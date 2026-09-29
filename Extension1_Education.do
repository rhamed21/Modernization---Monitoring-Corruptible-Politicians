* ==============================================================================
* SCRIPT: Extension 1 - Education & SES Heterogeneity
* PURPOSE: Testing if the electoral response to audits is stronger in 
* municipalities with higher baseline human capital and socioeconomic 
* status.
* ==============================================================================
capture log close
log using "$root/PR_audit/logfiles/extension2_educ.log", text replace

clear all
set more off

* ------------------------------------------------------------------------------
* 1. PREP: CENTER SES VARIABLES (1990 Baseline)
* ------------------------------------------------------------------------------
* We center the moderators (Education, Income, Poverty) at their sample means. 
* This ensures that the coefficient on 'pre_election' (the main effect) 
* represents the impact of a timely audit for a municipality with average 
* socioeconomic characteristics.

* Load and Set Data
use "$root/PR_audit/data/main_data_analysis_info_final.dta", clear
xtset munnumber election_year
eststo clear


* Education: % of population with College+ at baseline (1990)
summ base_perc_bchplus, meanonly
gen edu_c = base_perc_bchplus - r(mean)

* Income: Median HH income (scaled to $1000s) at baseline (1990)
summ base_hh_income_median, meanonly
gen inc_1k = (base_hh_income_median - r(mean)) / 1000

* Poverty: Poverty ratio at baseline (1990)
summ base_poverty_ratio, meanonly
gen pov_c = base_poverty_ratio - r(mean)

* ------------------------------------------------------------------------------
* 2. ANALYSIS: HETEROGENEITY IN ELECTORAL OUTCOMES
* Produce Table 8
* ------------------------------------------------------------------------------
* We use a high-dimensional fixed effects model (reghdfe) to interact the audit 
* indicator with our centered SES measures.

local corr_outcomes numfall_preport numfmay_preport numfjustice_preport shr_fmay_1 shr_fdoj_1

* Loop for Baseline and SES Robustness
foreach y of local corr_outcomes {

    * Model 1: Baseline Education Interaction
    * Testing if education alone moderates the audit effect.
     reghdfe `y' c.pre_election##c.edu_c $controls2_level, ///
        absorb(munnumber election_year) cluster(munnumber)
    eststo c_b_`y'

	* Model 2: Full SES Robustness
    * Adding interactions with income and poverty to ensure the education 
    * effect is not simply picking up general wealth/poverty effects.
     reghdfe `y' c.pre_election##c.edu_c c.pre_election##c.inc_1k ///
        c.pre_election##c.pov_c $controls2_level, ///
        absorb(munnumber election_year) cluster(munnumber)
        
	* Perform a joint F-test on the interaction terms
    quietly test c.pre_election#c.edu_c c.pre_election#c.inc_1k c.pre_election#c.pov_c
    estadd scalar joint_p = r(p)
    eststo c_s_`y'
}
* Summary statistics for the control group (untimely/future audits) for benchmarking
	summ numfall_preport numfmay_preport numfjustice_preport shr_fmay_1 shr_fdoj_1 if pre_election==0

	
	* ------------------------------------------------------------------------------
	* 3. EXPORT SHORT-TERM CORRUPTION RESULTS (Table 8)
	* ------------------------------------------------------------------------------

esttab c_b_* c_s_* using "$root/PR_audit/figures/Table8_Educ_Short_Corruption.rtf", replace ///
    title("Table 1: Educational and SES Heterogeneity in Corruption Outcomes") ///
    keep(pre_election c.pre_election#c.edu_c c.pre_election#c.inc_1k c.pre_election#c.pov_c) ///
    coeflabels(pre_election "Timely Audit" c.pre_election#c.edu_c "Audit × Education" ///
               c.pre_election#c.inc_1k "Audit × Income" c.pre_election#c.pov_c "Audit × Poverty") ///
    mtitles("Num. All" "Num. May" "Num. DOJ" "Sh.May" "Sh.DOJ" "Num.All (SES)" "Num. May (SES)" "Num. DOJ (SES)" "Sh. May (SES)" "Sh. DOJ (SES)") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) stats(N joint_p, labels("N" "Joint p-value") fmt(0 3)) ///
    addnotes("Municipality and Year FEs included. SES variables centered at mean.")

* ------------------------------------------------------------------------------
* 4. ANALYSIS: HETEROGENEITY IN LONG-TERM CORRUPTION (Table 9)
* ------------------------------------------------------------------------------
* Following the original paper's Table 4 logic, we include the 'Postpre_election' 
* (future audit) control to isolate the long-term impact of the initial shock.

local corr_outcomes_l numfall_preport_fup numfmay_preport_fup numfjustice_preport_fup shr_fmay_1_fup shr_fdoj_1_fup

* Loop for Baseline and SES Robustness
foreach y of local corr_outcomes_l {

    * Model 1: Baseline Education Interaction
    * Testing if education alone moderates the audit effect.
     reghdfe `y' c.pre_election##c.edu_c $controls2_level Postpre_election, ///
        absorb(munnumber election_year) cluster(munnumber)
    eststo clb_`y'

	* Model 2: Full SES Robustness
    * Adding interactions with income and poverty to ensure the education 
    * effect is not simply picking up general wealth/poverty effects.
     reghdfe `y' c.pre_election##c.edu_c c.pre_election##c.inc_1k ///
        c.pre_election##c.pov_c $controls2_level Postpre_election, ///
        absorb(munnumber election_year) cluster(munnumber)
        
	* Perform a joint F-test on the interaction terms
    quietly test c.pre_election#c.edu_c c.pre_election#c.inc_1k c.pre_election#c.pov_c
    estadd scalar joint_p = r(p)
    eststo cls_`y'
}
	summ numfall_preport_fup numfmay_preport_fup numfjustice_preport_fup shr_fmay_1_fup shr_fdoj_1_fup if pre_election==0

	* ------------------------------------------------------------------------------
	* 5. EXPORT LONG-TERM CORRUPTION RESULTS (Table 9)
	* ------------------------------------------------------------------------------
esttab clb_* cls_* using "$root/PR_audit/figures/Table9_Educ_Long_Corruption.rtf", replace ///
    title("Table 1: Education & Long-Term Corruption Outcomes") ///
    keep(pre_election c.pre_election#c.edu_c c.pre_election#c.inc_1k c.pre_election#c.pov_c) ///
    coeflabels(pre_election "Timely Audit" c.pre_election#c.edu_c "Audit × Education" ///
               c.pre_election#c.inc_1k "Audit × Income" c.pre_election#c.pov_c "Audit × Poverty") ///
    mtitles("Num. All" "Num. May" "Num. DOJ" "Sh.May" "Sh.DOJ" "Num.All (SES)" "Num. May (SES)" "Num. DOJ (SES)" "Sh. May (SES)" "Sh. DOJ (SES)") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) stats(N joint_p, labels("N" "Joint p-value") fmt(0 3)) ///
    addnotes("Municipality and Year FEs included. SES variables centered at mean.")
* ------------------------------------------------------------------------------
* 6. ANALYSIS: ELECTORAL OUTCOMES (Table 10)
* ------------------------------------------------------------------------------
* We examine electoral accountability (t) and long-term political survival (t+1).
* Note: We omit the 'Postpre_election' control here to match the authors' 
* preferred specification for electoral survival (Table 5).
eststo clear

* Panel A: Short-term (t) | Panel B: Long-term (t+1)
* Note: We follow the authors and OMIT Postpre_election control for Table 5 outcomes.
local elect_vars success_run run_reelection incumb_wins Postsuccess_run

foreach y of local elect_vars {
    
	* Apply sample restrictions: Wins are conditional on the incumbent choosing to run. local cond ""
    if "`y'" == "incumb_wins"      local cond "if run_reelection==1"
    if "`y'" == "Postincumb_wins"  local cond "if Postrun_reelection==1"

    * Model 1: Baseline Education Interaction
    * Testing if education alone moderates the audit effect.
    quietly reghdfe `y' c.pre_election##c.edu_c $controls2_level `cond', ///
        absorb(munnumber election_year) cluster(munnumber)
    eststo e_b_`y'

	* Model 2: Full SES Robustness
    * Adding interactions with income and poverty to ensure the education 
    * effect is not simply picking up general wealth/poverty effects.
    quietly reghdfe `y' c.pre_election##c.edu_c c.pre_election##c.inc_1k ///
        c.pre_election##c.pov_c $controls2_level `cond', ///
        absorb(munnumber election_year) cluster(munnumber)
        
	* Joint F-test on interaction coefficients
    quietly test c.pre_election#c.edu_c c.pre_election#c.inc_1k c.pre_election#c.pov_c
    estadd scalar joint_p = r(p)
    eststo e_s_`y'
}
	* Summary stats for electoral control group
	summ run_reelection if pre_election==0
	summ success_run if pre_election==0
	summ incumb_wins if run_reelection==1 & pre_election==0



	* ------------------------------------------------------------------------------
	* 7. EXPORT LONG-TERM CORRUPTION RESULTS (Table 10)
	* ------------------------------------------------------------------------------
esttab e_b_* e_s_* using "$root/PR_audit/figures/Table10_educ_Electoral.rtf", replace ///
    title("Table 2: Educational and SES Heterogeneity in Electoral Outcomes") ///
    keep(pre_election c.pre_election#c.edu_c c.pre_election#c.inc_1k c.pre_election#c.pov_c) ///
    coeflabels(pre_election "Timely Audit" c.pre_election#c.edu_c "Audit × Education") ///
    mtitles("Suc(t)" "Run(t)" "Win(t)" "Suc(t+1)" "Suc-S" "Run-S" "Win-S" "Suc-S+1") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) stats(N joint_p, labels("N" "Joint p-value") fmt(0 3)) ///
    addnotes("Panel B (t+1) models measure the total long-term effect of the audit shock.")

log close
