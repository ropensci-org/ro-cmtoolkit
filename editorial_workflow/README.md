# Editorial Workflow

This is a copy of the Editorial workflow used by editors when reviewing staff
or community blog posts to the [rOpenSci blog](https://ropensci.org/blog).

This is a relatively simple workflow and a script is not even necessary. 
However, in a Review there are quite a few minor moving pieces and this workflow
makes it quicker to find the files, review them, and perform some of the checks.

### A couple of points
- We use `usethis::pr_XXXX()` to handle PRs
- We use the interactive PR fetch so we don't have to know the PR number in advance
- We use `gert::git_diff` to make a best guess of the blog post md file. 
  It checks for new files added in this PR with the ".md" extension.
- We use `browseURL()` to open the URLs of the preview site and the PR files 
  (where the editor's comments will be made)
- We fetch the checklist text from the [Blog Guide](https://blogguide.ropensci.org/) 
  and format it to make it easy to copy from the console (used by the editor in their review)
- This checklist is slightly different if for a Peer Reviewed Package
- For the spell check, we ignore words which are:
    - the name of an rOpenSci package
    - in a local WORDLIST stored in "inst/WORDLIST" (and locally git-ignored i.e. `.git/info/exclude`)
- We use the `rstudioapi::navigateToFile()` function to open files in RStudio as
  needed.
