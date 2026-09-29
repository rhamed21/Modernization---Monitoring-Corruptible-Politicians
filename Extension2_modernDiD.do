capture log close
log using "$root/PR_audit/logfiles/extension2_modernDiD.log", text replace

* ==============================================================================
* SCRIPT: Extension 2 - Modern Difference-in-Differences (Robustness Check)
* PURPOSE: Re-estimating Bobonis et al. (2016) using a heterogeneity-robust 
* estimator to account for staggered treatment and potential negative 
* weights inherent in standard Two-Way Fixed Effects (TWFE).
* ==============================================================================

clear all
set more off

* ------------------------------------------------------------------------------
* 1. ENVIRONMENT & DATA SETUP
* ------------------------------------------------------------------------------
* Load main analysis dataset and ensure panel structure is sorted

use "$root/PR_audit/data/main_data_analysis_info_final.dta", clear
sort munnumber election_year

* Clear any previous estimates from memory
eststo clear

* ------------------------------------------------------------------------------
* 2. ESTIMATING CORRUPTION EFFECTS (did_multiplegt_dyn)
* Produce Table 11 and Figure 6
* ------------------------------------------------------------------------------
* We iterate through corruption outcomes using the de Chaisemartin & D'Haultfœuille 
* estimator. This allows for non-binary/non-absorbing treatment designs.
	* effects(2): Estimates instantaneous (t) and dynamic (t+1) effects.
    * placebo(2): Estimates t-1 and t-2 to test the Parallel Trends Assumption.
    * controls: Includes the baseline vector defined in the master script.
	
local main_outcomes "numfall_preport numfmay_preport numfjustice_preport shr_fmay_1 shr_fdoj_1"

foreach var in `main_outcomes' {
    quietly did_multiplegt_dyn `var' munnumber election_year pre_election, ///
        effects(2) placebo(2) controls($controls2_level) cluster(munnumber) ///
        graphoptions(scheme(s1color) /// 
                     yline(0, lcolor(black) lpattern(dash)) ///
                     xtitle(Election Period) ///
                     ytitle(Estimated Treatment Effect) ///
                     ylabel(, angle(horizontal)) ///
                     legend(off))
        
    * 2. Save the formatted Event Study Graph (Figure 6 )
    graph export "$root/PR_audit/figures/figure5_`var'.png", as(png) replace
    graph close _all
    
    * 3. Extract and Store Scalars
    estimates store `var'
    estadd scalar n_eff1       = e(N_effect_1)
    estadd scalar n_eff2       = e(N_effect_2)
    estadd scalar n_pl1        = e(N_placebo_1)
    estadd scalar switch_eff1  = e(N_switchers_effect_1)
    estadd scalar switch_eff2  = e(N_switchers_effect_2)
    estadd scalar switch_pl1   = e(N_switchers_placebo_1)
}
	* ==============================================================================
	* EXPORT RESULTS (TABLE 11)
	* ==============================================================================

local main_outcomes "numfall_preport numfmay_preport numfjustice_preport shr_fmay_1 shr_fdoj_1"

esttab `main_outcomes' using "$root/PR_audit/figures/Table11_did_Corruption.rtf", replace ///
    title("Short and Long-Term Effects of Audits (modern DiD)") ///
    keep(Effect_1 Effect_2 Placebo_1) ///
    order(Effect_1 Effect_2 Placebo_1) ///
    coeflabels(Effect_1 "Timely Audit (t)" ///
               Effect_2 "Timely Audit (t)" ///
               Placebo_1 "Placebo Test (t-1)") ///
    refcat(Effect_1 "{\b Panel A: Short-Term Effect (t)}" ///
           Effect_2 "{\b Panel B: Long-Term Effect (t+1)}" ///
           Placebo_1 "{\b Panel C: Parallel Trends Check (t-1)}", nolabel) ///
    mtitles("All" "Mayor" "DOJ" "Share Mayor" "Share DOJ") ///
    stats(switch_eff1 n_eff1 switch_eff2 n_eff2 switch_pl1 n_pl1, ///
          labels("Switchers (t)" "N (t)" "Switchers (t+1)" "N (t+1)" "Switchers (Pl)" "N (Pl)") ///
          fmt(0)) ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    addnotes("Standard errors clustered by municipality. Panel A and B report the estimated impact of a timely audit. Panel C reports the placebo effect at t-1.")
	
* ------------------------------------------------------------------------------
* 3. ELECTORAL MECHANISMS (Modern DiD)
* Produce Table 12
* ------------------------------------------------------------------------------
* Analyzing how the audit disclosure impacts candidate entry and reelection.
eststo clear

* 1. Primary Results (Municipality FE)
foreach var in success_run run_reelection { 
     did_multiplegt_dyn `var' munnumber election_year pre_election, ///
        controls($controls2_level) effects(2) placebo(2) cluster(munnumber)
    
    * Standardize names: lowercase 'n' and 'sw' for brevity
    estadd scalar n_t1  = e(N_effect_1)
    estadd scalar sw_t1 = e(N_switchers_effect_1)
    estadd scalar n_t2  = e(N_effect_2)
    estadd scalar sw_t2 = e(N_switchers_effect_2)
    estadd scalar n_pl  = e(N_placebo_1)
    estadd scalar sw_pl = e(N_switchers_placebo_1)
    
    estimates store `var'_mun
    graph close _all   
}

* 4. CONDITIONAL MODEL: WINS GIVEN RUNNING
* Restricted sample to test if the audit affects the win rate of those who 
* actually choose to seek reelection.
 did_multiplegt_dyn incumb_wins munnumber election_year pre_election ///
    if run_reelection==1, ///
    controls($controls2_level) effects(2) placebo(2) cluster(munnumber)

estadd scalar n_t1  = e(N_effect_1)
estadd scalar sw_t1 = e(N_switchers_effect_1)
estadd scalar n_t2  = e(N_effect_2)
estadd scalar sw_t2 = e(N_switchers_effect_2)
estadd scalar n_pl  = e(N_placebo_1)
estadd scalar sw_pl = e(N_switchers_placebo_1)

estimates store win_cond_mun
graph close _all

* ------------------------------------------------------------------------------
* 5. EXPORT RESULTS (Table 12)
* ------------------------------------------------------------------------------
* Exporting formatted tables to RTF for inclusion in the final manuscript.

esttab success_run_mun run_reelection_mun win_cond_mun ///
    using "$root/PR_audit/figures/Table12_did_electoral.rtf", replace ///
    title("Table 9: Electoral Accountability Mechanisms") ///
    mtitles("Runs & Wins" "Runs" "Wins|Runs") ///
    keep(Effect_1 Effect_2 Placebo_1) ///
    order(Effect_1 Effect_2 Placebo_1) ///
    coeflabels(Effect_1 "Timely Audit (t)" ///
               Effect_2 "Timely Audit (t+1)" ///
               Placebo_1 "Placebo Test (t-1)") ///
    stats(sw_t1 n_t1 sw_t2 n_t2 sw_pl n_pl, ///
          labels("Switchers (t)" "N (t)" "Switchers (t+1)" "N (t+1)" "Switchers (Pl)" "N (Pl)") ///
          fmt(0)) ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)

log close
exit
