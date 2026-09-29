* ==========================================================
* MASTER REPLICATION SCRIPT: Bobonis et al. (2016)
* By Roa'a Hamed
* ==========================================================
clear all
set more off
macro drop _all

* 1. USER ACTION REQUIRED: Set the path to the project folder "Bobonis-Replication"
global root "/Users/roaa/Library/CloudStorage/GoogleDrive-roaa.hamed21@gmail.com/My Drive/Downloads/Bobonis-Replication"

* 2. Ensure the output directories exist
capture mkdir "$root/PR_audit/figures"
capture mkdir "$root/PR_audit/logfiles"


* 3. INSTALL REQUIRED PACKAGES (if not already installed)
ssc install reghdfe, replace
ssc install ftools, replace
ssc install estout, replace
ssc install did_multiplegt_dyn, replace

*4. RUN ORIGINAL REPLICATION (Author files) - with documented corrections (readme)
*/Produces Figure 1-5, Table 1-7*/
do "$root/PR_audit/dofiles/prep_Figure1_timing_audits_16-05-12.do"
do "$root/PR_audit/dofiles/analysis_auditinfo_elect_annual_ver_16-05-11.do"
do "$root/PR_audit/dofiles/analysis_dynamCorrupt_16-05-10.do"

* 5. RUN EXTENSIONS
*/Produces Figure 6, Table 8-12*/
do "$root/PR_audit/dofiles/Extension1_Education.do"
do "$root/PR_audit/dofiles/Extension2_modernDiD.do"



