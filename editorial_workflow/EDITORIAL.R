# Clean up previous PR if necessary
usethis::pr_finish()

# Fetch current PRs interactively
usethis::pr_fetch()
pr <- 830             # <--- Update PR number when you get it
pkg <- FALSE          # <--- Is this a post about a Peer-Reviewed Package?

# Get the relevant md file (and check)
(b <- gert::git_diff("HEAD^")$new |> stringr::str_subset("\\.md$"))

# Open preview in browser
browseURL(paste0("https://deploy-preview-", pr, "--ropensci.netlify.app/"))

# Open PR files in browser
browseURL(paste0("https://github.com/ropensci/roweb3/pull/", pr, "/files"))

# Checklists to copy
paste(
  "* [ ]",
  c(readLines("https://raw.githubusercontent.com/ropensci-org/blog-guidance/main/inst/checklists/editor-checklist.csv"),
    if(pkg) readLines("https://raw.githubusercontent.com/ropensci-org/blog-guidance/main/inst/checklists/editor-checklist-peer-reviewed-pkg.csv"))
) |> 
  cat(sep = "\n")

# Local checks
roblog::ro_lint_md(b)
roblog::ro_check_urls(b)
spelling::spell_check_files(b, ignore = c(spelling::get_wordlist(), promoutils::pkgs()$name))

# Update wordlist manually as needed - This is specific to each Editor, locally git ignored 
# rstudioapi::navigateToFile("inst/WORDLIST")

# Open file in RStudio if required
rstudioapi::navigateToFile(b)

# Wrap up
usethis::pr_finish(pr)
