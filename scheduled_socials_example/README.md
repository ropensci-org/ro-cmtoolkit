# Scheduling Mastodon posts - Example files

This is an example of how to use GitHub Issues and Actions to schedule
Mastodon posts via [rtoot](https://schochastics.github.io/rtoot/). 


## In a nutshell...
- Issues are posts (using a [Issue template](.github/ISSUE_TEMPLATE/schedule-post.md))
  - YAML has time to post, alt text, any media is embedded etc.
- Mastodon credentials are stored as GitHub secrets
- [GitHub actions](.github/workflows/schedule_posts.yaml) run `schedule_posts.R` script
  - on CRON Job
  - manually (`workflow_dispatch` event trigger)
- Script 
  - Fetches open issues, omits those labeled 'draft'
  - Issues are posted to Mastodon if the post hour is within or earlier than time of the run
  - Posted issues are then closed
  - If there are multiple posts, there is a 5 min `Sys.sleep()` between posts
- We use [renv](https://rstudio.github.io/renv/articles/renv.html) to handle 
  consistent package dependencies

## Considerations
- Any one who can make an issue could post to Mastodon via the stored credentials :scream:
- Running the actions Hourly can use up a lot of run minutes. 
  - We schedule specific hours we usually use and use the manual run the rest of the time
- GitHub actions run in UTC

## Issue template
- See [example template](.github/ISSUE_TEMPLATE/schedule-post.md)
- 'Draft' Label is automatically applied 
  - needs to be removed for an issue to be posted
- Require YAML for `time` and `tz`
- Optional, `alt` (required if media present)
- Use `~~~` to separate YAML from body (better formatting than `---`)
- Include up to one image in the body directly (embedded) (`alt` is required if media present)
- Emojis can be code or Unicode (i.e. :tada: or `:tada:`)

## GitHub Actions
- See [example action](.github/workflows/schedule_posts.yaml)
- Run by `workflow_dispatch` or on `scheduled`
- Uses credentials stored as GitHub Secrets - `RTOOT_DEFAULT_TOKEN`
- Sets up R with renv
- Caches packages for quick runs (using `renv::restore()`)
- Runs `schedule_posts.R`

## Posting to Mastodon
- See [example R script](schedule_posts.R)
- Grabs issues from GitHub
- Extracts and cleans metadata from YAML (see functions in `details.R`)
- Ignores `draft` issues
- Ignores issues with a post date in the future
- Downloads any media included (and enforces alt text)
- Posts to Mastodon
- Closes issue
- If more than one issue, waits 5 min before posting the next\*


\* This may not be the best way to do this, as waiting 5min with `Sys.sleep()`
still means that the GitHub action minutes are being used up. It may be worth
exploring the `scheduled_at` argument of `rtoot::post_toot()` instead.

## Setting up Authentication

Credentials are stored as a GitHub secret for Actions

**Get the token:** (replace `hachyderm.io` with your Mastodon instance)

```
rtoot::auth_setup("hachyderm.io", type = "user", name = "XXXX", clipboard = TRUE)
```

**Add the token:** 

In GitHub > Settings > Secrets and variables > Actions

Edit/Add the "RTOOT_TOKEN_ROPENSCI" secret and add the

`XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX;user;hachyderm.io`

part of the copied text (i.e. omit the `RTOOT_DEFAULT_TOKEN=` bit and quotes)


## Troubleshooting
- If Actions fail for package dependency reasons after runs with no problems
  - Try deleting [cache](https://github.com/rosadmin/scheduled_socials/actions/caches) 
    and restarting failed run
  
