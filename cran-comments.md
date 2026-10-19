## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

Updates based on CRAN feedback:

* update the rd files for functions missing \value content
* update print method for placeholder_tbl to not mix cli and text outputs to support message suppression. 
* clarified with reviewer that the "print()" call in save_pptx does not actually print anything to the console - this is for saving the pptx using the {officer} package print method
