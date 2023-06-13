
/*******************************************************************************
File: agg_data_figures
Purpose: Plot the fit of the Phillips curve at the aggregate level
Last Update: October 1st, 2021.
*******************************************************************************/
clear all
set more off
 set matsize 800
eststo clear
clear matrix

 
* Set the local name with your name.
local name = "juan"


* set your path under your name
if "`name'" == "juan" { 
cd "/Users/juanherreno/Dropbox/Investigacion/StateLevelCPIs/"
}

if  "`name'" == "emi" {
cd "e:/mydocs/dropbox/StateLevelCPIs/"
}

if  "`name'" == "joe" {
cd "/Users/joehazell/Dropbox/StateLevelCPIs//"
}

if  "`name'" == "jon" {
cd ""
}

if "`name'" == "juan_pc" { 
cd "C:/Users/jdh2181/Dropbox/Investigacion/StateLevelCPIs/"
}

use "ReplicationPackage/code_to_share/agg_data.dta", clear
sort time
gen counter = _n
tsset counter


keep if year >= 1979
keep if year <= 2017
// Fix format for the figures.
label var spf_cpi_lt "SPF CPI LT Inflation Expectations"
label var time "Time"
label var date "Time"


label var spf_cpi_lt "SPF CPI LT Inflation Expectations"
label var time "Time"
label var date "Time"


* Set kappa. Comes from Table 4.
global kappa1 0.0062 // Treadable Demand IV estimate, full sample
global kappa2 0.0109 // Tradeable Demand IV estimate, pre 1990
global kappa3 0.0055 // Tradeable Demand IV estimate, pos 1990

// fix these figure.s
global kappa_rent 0.0243 // rent estimate, new sample

* Set value of beta
global beta 0.99
global truncate_length 20

* Calculate scaling factor 
foreach u_rate in  urate_cyc {

	* Create truncated present value of u rate
	*quietly capture drop u_sum_`u_rate'
	quietly generate u_sum_`u_rate' = `u_rate'

	
	forvalues ii = 1/$truncate_length {
		*quietly replace u_sum_`u_rate' =  $beta^`ii'*F`ii'.`u_rate'
		quietly replace u_sum_`u_rate' = u_sum_`u_rate' + $beta^`ii'*F`ii'.`u_rate'
	}
	
	* Estimate scaling factor 
	regress u_sum_`u_rate' `u_rate', r
	* Save scaling factor with right name 
	scalar zeta_`u_rate' = _b[`u_rate']
}


set graphics on
foreach u_rate in urate_cyc {
foreach infl_rate in   cpi_rs_core cpi_lessfe_shelter {
	forvalues ii = 1/3{
		global jj `ii'
		constraint 1 lag_urate = - ${kappa$jj} * 4 * zeta_`u_rate' // psi for non-shelter cpi less food and energy
		cnsreg lhs_`infl_rate'_lt  lag_urate, constraints(1)
		predict `infl_rate'_hat, xb
		* Weights are 0.42 housing 0.58 non-housing. See https://www.bls.gov/opub/hom/pdf/cpihom.pdf for weights.
		constraint 2 lag_urate = - (0.5839*${kappa$jj} * 4 * zeta_`u_rate' + (1-0.5839)*${kappa_rent} * 4 * zeta_`u_rate') // psi for core.
		cnsreg lhs_`infl_rate'_lt  lag_urate, constraints(2)
		predict `infl_rate'_hat2, xb
		graph twoway (line lhs_`infl_rate'_lt time) (line `infl_rate'_hat time)
		graph save "ReplicationPackage/code_to_share/Graphs/`u_rate'_`infl_rate'_kappa_`ii'", replace 
		graph twoway (line lhs_`infl_rate'_lt time) (line `infl_rate'_hat2 time)
		graph save "ReplicationPackage/code_to_share/Graphs/`u_rate'_`infl_rate'_kappa_`ii'_rent", replace 
		drop `infl_rate'_hat `infl_rate'_hat2
	}
}
}
// Delete figures that won't be used. These are combinations of kappa including rent and CPI excluding rent, and viceversa.
erase "ReplicationPackage/code_to_share/Graphs/urate_cyc_cpi_lessfe_shelter_kappa_1_rent.gph"
erase "ReplicationPackage/code_to_share/Graphs/urate_cyc_cpi_lessfe_shelter_kappa_2_rent.gph"
erase "ReplicationPackage/code_to_share/Graphs/urate_cyc_cpi_lessfe_shelter_kappa_3_rent.gph"
erase "ReplicationPackage/code_to_share/Graphs/urate_cyc_cpi_lessfe_shelter_kappa_1.gph"
erase "ReplicationPackage/code_to_share/Graphs/urate_cyc_cpi_lessfe_shelter_kappa_2.gph"
erase "ReplicationPackage/code_to_share/Graphs/urate_cyc_cpi_rs_core_kappa_1.gph"
erase "ReplicationPackage/code_to_share/Graphs/urate_cyc_cpi_rs_core_kappa_2.gph"
erase "ReplicationPackage/code_to_share/Graphs/urate_cyc_cpi_rs_core_kappa_3.gph"
erase "ReplicationPackage/code_to_share/Graphs/urate_cyc_cpi_rs_core_kappa_1_rent.gph"
erase "ReplicationPackage/code_to_share/Graphs/urate_cyc_cpi_rs_core_kappa_2_rent.gph"

set graphics on

constraint 3 lag_urate = - (0.5839*${kappa2} * 4 * zeta_urate_cyc + (1-0.5839)*${kappa_rent} * 4 * zeta_urate_cyc) // psi for core.
cnsreg lhs_cpi_rs_core_lt  lag_urate, constraints(3)
predict cpi_rs_core_hat_pre, xb

constraint 4 lag_urate = - (0.5839*${kappa3} * 4 * zeta_urate_cyc + (1-0.5839)*${kappa_rent} * 4 * zeta_urate_cyc) // psi for core.
cnsreg lhs_cpi_rs_core_lt  lag_urate, constraints(4)
predict cpi_rs_core_hat_pos, xb
graph twoway (line cpi_rs_core_hat_pre time) (line cpi_rs_core_hat_pos time)
save "ReplicationPackage/code_to_share/Graphs/flattening_fit.gph", replace




