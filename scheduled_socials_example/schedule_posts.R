# This script is run by GitHub actions to grab and post issues to Mastodon.
# You can test it locally *if* you have the Rtoot token locally (see ?rtoot::auth_setup)
# You can also test it without posting by using testing <- TRUE.
# The message blocks are to help with trouble shooting the GitHub actions,
# if needed.

library(gh)
library(rtoot)
library(dplyr)
library(purrr)
library(yaml)
library(stringr)
library(lubridate)
library(tidyr)
library(pandoc)

source("details.R")

testing <- FALSE # If testing, don't actually post

# First make sure we're good to go
verify_envvar() # GitHub Secret RTOOT_DEFAULT_TOKEN

# Get issues and filter to non-draft ('owner' and 'repo' are set in details.R)
issues <- gh(endpoint = "/repos/{owner}/{repo}/issues",
             owner = owner, repo = repo, state = "open", .limit = Inf)

i <- tibble(number = purrr::map_chr(issues, "number"),
            body = purrr::map_chr(issues, "body"),
            labels = purrr::map(issues, "labels")) |>
  dplyr::mutate(labels = map_depth(.data$labels, 2, "name")) |>
  # Omit issues labeled "draft"
  mutate(draft = map_lgl(labels, ~any(.x == "draft"))) |>
  filter(!draft)

if(nrow(i) > 0) {
  i <- i |>
    mutate(
      # Extract and remove metadata
      yml = map(body, str_extract, yaml_pattern),
      yml = map(yml, yaml_extract),
      body = map_chr(body, str_remove, yaml_pattern),

      # Look for media files
      media = map_chr(body, str_extract, media_pattern),
      media = map_chr(media, str_extract, "http([^\\)])*"),
      media_ok = map_lgl(media, ~!is.na(.x) && crul::ok(.x, verb = "get")),

      # Clean up the body text
      body = map_chr(body, str_remove, media_pattern),
      body = str_trim(body),
      body = map_chr(body, replace_emoji)) |>
    tidyr::unnest(yml) |>
    mutate(time = map2(time, tz, ~ymd_hms(.x, tz = .y, truncated = 2))) |>
    tidyr::unnest(time)

  # No posting media if no Alt
  if(any(i$media_ok & i$alt == "")) {
    stop("Cannot post if media present without alt text\n",
         "  Problem with issue(s):\n",
         paste0(
           paste0("  - https://github.com/", owner, "/", repo, "/issues/",
                  i$number[i$media_ok & i$alt == ""], "\n"),
           collapse = ", "),
         call. = FALSE)
  }


  # Get posts to run (i.e. everything up until this hour)
  i <- i |>
    mutate(time = with_tz(time, "UTC")) |> # GitHub Actions run in UTC
    filter(time <= floor_date(Sys.time(), unit = "hour"))


  if(nrow(i) > 0) {

    n_posts <- seq_len(nrow(i))

    for(n in n_posts) {

      body <- i$body[n]

      # Download media file if present
      if(i$media_ok[n]) {
        alt <- i$alt[n]
        media <- paste0("temp_media", str_extract(i$media[n], "\\.\\w+$"))
        download.file(i$media[n], destfile = media)
      } else {
        alt <- NULL
        media <- NULL
      }

      message("\n---") # Start message block

      if(!testing) { # Don't post when testing!
        message("\nTooting issue: ", i$number[n],
                "\nAt: ", Sys.time())
        post_toot(status = body, media = media, alt = alt) # Token from environment
      } else {
        message("\nA post would normally have been sent at ", Sys.time(), ":",
                "\nTime: ", i$time[n],
                "\nIssue: ", i$number[n],
                "\nBody: ", body,
                "\nMedia: ", media,
                "\nAlt text: ", alt)
      }


      # Close issue
      message("Closing issue: ", i3$number[n])
      gh::gh(endpoint = "/repos/{owner}/{repo}/issues/{number}",
             owner = owner, repo = repo, number = i$number[n],
             state = "closed",
             .method = "PATCH")

      # Clean up
      unlink(media)

      # Give at least 5 minutes between posts
      if(max(n_posts) > n) {
        message("Waiting before next post...")
        Sys.sleep(60 * 5)
      }

      message("\n---\n") # finish message block
    }

  } else {
    message("\n---\nNo posts this time\n---\n")
  }
} else {
  message("\n---\nNo posts this time\n---\n")
}
