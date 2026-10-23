/*******************************************************************************
                    Problem Set 2: Multiple hypothesis testing

                          Universidad de San Andrés
                              Economía Aplicada
							       2024
*******************************************************************************/

* Paper: Attanasio, Cattan, Fitzsimons, Meghir y Rubio-Codina (2020), AER 110(1)

/*******************************************************************************
Este archivo sigue la siguiente estructura:

0) Set up environment and globals

1) Labels

2) Regressions (Tabla 2 del paper)

3) Corrections (Bonferroni, Holm y Benjamini-Krieger-Yekutieli)

4) Export tables

*******************************************************************************/


* 0) Set up environment
*==============================================================================*
clear all
set more off
* directorio: completar con la ruta a la carpeta del problem set
gl main ""
gl input "$main/input"
gl output "$main/output"

cap which esttab
if _rc ssc install estout

* Open data set
use "$input/measures.dta", clear 

* Global with control variables
global covs_eva	"male i.eva_fu" 
global covs_ent	"male i.ent_fu"

* 1) Labels
*==============================================================================*

label var b_tot_cog1_st "Bayley: Cognitive"
label var b_tot_lr1_st "Bayley: Receptive language"
label var b_tot_le1_st "Bayley: Expressive language"
label var b_tot_mf1_st "Bayley: Fine motor"
label var mac_words1_st "MacArthur: Words the child can say"
label var mac_phrases1_st "MacArthur: Complex phrases the child can say"
label var bates_difficult1_st "ICQ: Difficult(-)"
label var bates_unsociable1_st "ICQ: Unsociable(-)"
label var bates_unstoppable1_st "ICQ: Unstoppable(-)"
label var roth_inhibit1_st "ECBQ: Inhibitory control"
label var roth_attention1_st "ECBQ: Attentional focusing"
label var fci_play_mat_type1_st "FCI: Number of types of play materials"
label var Npaintbooks1_st "FCI: Number of coloring and drawing books"
label var Nthingsmove1_st "FCI: Number of toys to learn movement"
label var Ntoysshape1_st "FCI: Number of toys to learn shapes"
label var Ntoysbought1_st "FCI: Number of shop-bought toys"
label var fci_play_act1_st  "FCI: Number of types of play activities in last 3 days"
label var home_stories1_st "FCI: Number of times told a story to child in last 3 days"
label var home_read1_st "FCI: Number of times read to child in last 3 days"
label var home_toys1_st "FCI: Number of times played with toys in last 3 days"
label var home_name1_st "FCI: Number of times named things to child in last 3 days"
label var treat "Treatment"


* 2) Regressions
*==============================================================================*

* Cada regresión se guarda como m1, ..., m21 y su p-valor (H0: treat = 0) se
* guarda en la matriz P, junto con el panel al que pertenece (1=A, ..., 4=D).

local bayley "b_tot_cog b_tot_lr b_tot_le b_tot_mf"
local macarthur "mac_words mac_phrases"
local bates "bates_difficult bates_unsociable bates_unstoppable" 
local roth "roth_inhibit roth_attention" 
local fcimat "fci_play_mat_type Npaintbooks Nthingsmove Ntoysshape Ntoysbought"
local fcitime "fci_play_act home_stories home_read home_toys home_name"

eststo clear
mat P = J(21, 2, .)
local i = 0

******************************************************************************* 
* PANEL A (Child's cognitive skills at follow up) 
******************************************************************************* 

foreach y of local bayley {
	local ++i
	eststo m`i': reg `y'1_st treat `y'0_st $covs_eva, cluster(cod_dane)
	test treat = 0
	mat P[`i',1] = r(p)
	mat P[`i',2] = 1
} 

foreach y of local macarthur {
	local ++i
	eststo m`i': reg `y'1_st treat mac_words0_st $covs_ent, cluster(cod_dane)
	test treat = 0
	mat P[`i',1] = r(p)
	mat P[`i',2] = 1
} 

******************************************************************************* 
* PANEL B (Child's socio-emotional skills at follow up) 
******************************************************************************* 

foreach y of local bates {
	local ++i
	eststo m`i': reg `y'1_st treat `y'0_st $covs_ent, cluster(cod_dane)
	test treat = 0
	mat P[`i',1] = r(p)
	mat P[`i',2] = 2
} 

foreach y of local roth {
	local ++i
	eststo m`i': reg `y'1_st treat bates_difficult0_st $covs_ent, cluster(cod_dane)
	test treat = 0
	mat P[`i',1] = r(p)
	mat P[`i',2] = 2
} 

******************************************************************************* 
* PANEL C (Material investments)  
******************************************************************************* 

foreach y of local fcimat {
	local ++i
	eststo m`i': reg `y'1_st treat fci_play_mat_type0_st $covs_ent, cluster(cod_dane)
	test treat = 0
	mat P[`i',1] = r(p)
	mat P[`i',2] = 3
} 

******************************************************************************* 
* PANEL D (Time investments)  
******************************************************************************* 

foreach y of local fcitime {
	local ++i
	eststo m`i': reg `y'1_st treat fci_play_act0_st $covs_ent, cluster(cod_dane)
	test treat = 0
	mat P[`i',1] = r(p)
	mat P[`i',2] = 4
} 


* 3) Corrections
*==============================================================================*

* Familia de hipótesis = cada panel de la tabla (A: 6, B: 5, C: 5, D: 5).

preserve
clear
svmat P
rename (P1 P2) (pval panel)
gen outcome = _n

* número de hipótesis de cada familia
bysort panel: gen m = _N

******************************************************************************* 
* a. Bonferroni: p ajustado = min(1, m*p)
******************************************************************************* 

gen p_bonf = min(1, pval*m)

******************************************************************************* 
* b. Holm: se ordenan los p-valores de menor a mayor dentro de cada familia y
*    p ajustado(j) = max_{k<=j} min(1, (m-k+1)*p(k))
******************************************************************************* 

bysort panel (pval): gen p_holm = min(1, (m - _n + 1)*pval)
bysort panel (pval): replace p_holm = max(p_holm, p_holm[_n-1]) if _n > 1

******************************************************************************* 
* c. Benjamini, Krieger y Yekutieli (2006): sharpened q-values
*    (adaptación del código de Michael Anderson, aplicado dentro de cada familia)
******************************************************************************* 

gen q_bky = .
forvalues k = 1/4 {
	quietly count if panel == `k'
	local totalpvals = r(N)
	
	* ranking de los p-valores dentro de la familia
	gen int rank = .
	bysort panel (pval): replace rank = _n if panel == `k'
	gen bky_tmp = 1 if panel == `k'
	
	* se chequea qué hipótesis se rechazan con q = 1, 0.999, ..., 0.001
	forvalues s = 1000(-1)1 {
		local qval = `s'/1000
		
		* Primera etapa: q' = q/(1+q)
		local qval_adj = `qval'/(1+`qval')
		gen fdr_temp1 = `qval_adj'*rank/`totalpvals' if panel == `k'
		gen reject_temp1 = (fdr_temp1 >= pval) if panel == `k'
		gen reject_rank1 = reject_temp1*rank
		egen total_rejected1 = max(reject_rank1)
		
		* Segunda etapa: q_2st = q'*(M/m0), con m0 = M - rechazadas en la 1ra etapa
		local qval_2st = `qval_adj'*(`totalpvals'/(`totalpvals'-total_rejected1[1]))
		gen fdr_temp2 = `qval_2st'*rank/`totalpvals' if panel == `k'
		gen reject_temp2 = (fdr_temp2 >= pval) if panel == `k'
		gen reject_rank2 = reject_temp2*rank
		egen total_rejected2 = max(reject_rank2)
		
		* una hipótesis se rechaza al nivel q si su rank es <= al máximo rank rechazado
		replace bky_tmp = `qval' if rank <= total_rejected2 & panel == `k'
		drop fdr_temp* reject_temp* reject_rank* total_rejected*
	}
	replace q_bky = bky_tmp if panel == `k'
	drop rank bky_tmp
}

sort outcome
list outcome panel pval p_bonf p_holm q_bky, sep(0)
save "$output/pvalues_corregidos.dta", replace
mkmat pval p_bonf p_holm q_bky, matrix(C)
restore

* agregamos los p-valores (originales y corregidos) a cada regresión guardada
forvalues i = 1/21 {
	estadd scalar p_value = C[`i',1] : m`i'
	estadd scalar p_bonf  = C[`i',2] : m`i'
	estadd scalar p_holm  = C[`i',3] : m`i'
	estadd scalar q_bky   = C[`i',4] : m`i'
}


* 4) Export tables
*==============================================================================*

local all ""
forvalues i = 1/21 {
	local all "`all' m`i'"
}

* Tabla del punto 1 (las 21 regresiones)
esttab `all' using "$output/Table_4.rtf", se replace label noobs ///
       keep(treat) ///
       cells(b(fmt(3) star) se(par fmt(3))) ///
       star(* 0.10 ** 0.05 *** 0.01) ///
       stats(N, fmt(0) labels("Sample size"))

* Tabla del punto 3 (la misma tabla + p-valores corregidos)
esttab `all' using "$output/Table_4_Corrected.rtf", se replace label noobs ///
       keep(treat) ///
       cells(b(fmt(3) star) se(par fmt(3))) ///
       star(* 0.10 ** 0.05 *** 0.01) ///
       stats(N p_value p_bonf p_holm q_bky, fmt(0 3 3 3 3) ///
       labels("Sample size" "P-value" "Bonferroni" "Holm" "BKY (sharpened q-value)"))

* Versiones LaTeX: un archivo por panel, con los outcomes en las columnas
local A "m1 m2 m3 m4 m5 m6"
local B "m7 m8 m9 m10 m11"
local C "m12 m13 m14 m15 m16"
local D "m17 m18 m19 m20 m21"
local tA `""Cognitive" "Receptive lang." "Expressive lang." "Fine motor" "Words" "Phrases""'
local tB `""Difficult (-)" "Unsociable (-)" "Unstoppable (-)" "Inhibitory control" "Attentional focusing""'
local tC `""Play materials" "Coloring books" "Toys movement" "Toys shapes" "Shop-bought toys""'
local tD `""Play activities" "Told a story" "Read to child" "Played with toys" "Named things""'

foreach p in A B C D {
	esttab ``p'' using "$output/Tabla 1 - Panel `p'.tex", replace booktabs label ///
		keep(treat) b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) nonotes noobs ///
		mtitles(`t`p'') stats(N, fmt(%9.0fc) labels("Observaciones"))
	esttab ``p'' using "$output/Tabla 2 - Panel `p'.tex", replace booktabs label ///
		keep(treat) b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) nonotes noobs ///
		mtitles(`t`p'') stats(N p_value p_bonf p_holm q_bky, fmt(%9.0fc 3 3 3 3) ///
		labels("Observaciones" "p-valor" "Bonferroni" "Holm" "BKY (q-valor)"))
}
