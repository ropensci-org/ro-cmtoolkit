# Repo Details ---------------------------

owner <- "github_user" # Organization or Username
repo <- "github_repo"  # Repository

# Matching patterns ----------------------
media_pattern <- "!\\[(.)*\\]\\((.)+\\)"
yaml_pattern <- regex("~~~(.)*~~~", dotall = TRUE)

# Extract YAML metadata --------------------
yaml_extract <- function(yaml) {
  y <- str_remove_all(yaml, "~~~") %>%
    yaml.load() %>%
    map_if(is.null,  ~"") %>%
    data.frame()

  # Catch common typos
  names(y) <- tolower(names(y))

  y
}

# Replace 'code' emojis with 'real' emojis -----------------------------
# x <- "hi :tada: testing \n\n\n Whow ! 🔗 \n\n\n :smile:"
replace_emoji <- function(x) {
  emo <- str_extract_all(x, "\\:.+\\:") |>
    unlist() |>
    unique()

  if(length(emo) > 1) {
    emo <- setNames(
      map(emo, ~pandoc::pandoc_convert(
        text = .x, from = "markdown+emoji", to = "plain")) |> unlist(),
      nm = emo)

   x <- str_replace_all(x, emo)
  }
  x
}
