/*******************************************************************************
							    Problem Set 7
                        Cluster robust inference

                          Universidad de San Andrés
                              Economía Aplicada
									2024							           
*******************************************************************************/

/*******************************************************************************
Este do-file estima el efecto del tratamiento sobre la obtención del Bagrut
con cuatro estrategias de inferencia: errores robustos, errores clusterizados,
wild cluster bootstrap y approximate randomization test (ART).
*******************************************************************************/

clear all
set more off

* directorio: completar con la ruta a la carpeta del problem set
global main ""
global input "$main/input"
global output "$main/output"
global programs "$main/programs"

* paquetes necesarios (se instalan solo si no están)
foreach pkg in estout boottest {
	cap which `pkg'
	if _rc ssc install `pkg'
}
* art.ado define funciones de Mata sin declarar las variables, así que hay que
* compilarlo con matastrict apagado (si está prendido da "variable undeclared")
set matastrict off
cap program drop art
cap mata: mata drop crs_work() pval()
run "$programs/art.ado"

use "$input/base01.dta", clear

gen group = 1
replace group = 2 if pair == 2 | pair == 4
replace group = 3 if pair == 5 | pair == 8
replace group = 4 if pair == 7
replace group = 5 if pair == 9 | pair == 10
replace group = 6 if pair == 11
replace group = 7 if pair == 12 | pair == 13
replace group = 8 if pair == 14 | pair == 15
replace group = 9 if pair == 16 | pair == 17
replace group = 10 if pair == 18 | pair == 20
replace group = 11 if pair == 19

label var treated "Treated"
label var zakaibag "Bagrut"

*==============================================================================*

* 1) Robust standard errors (con efectos fijos por grupo)

areg zakaibag treated semarab semrel, absorb(group) robust
scalar b1 = _b[treated]
scalar se1 = _se[treated]
scalar p1 = 2*ttail(e(df_r), abs(_b[treated]/_se[treated]))
scalar n1 = e(N)
est store reg1

*==============================================================================*

* 2) Cluster robust SE (con efectos fijos por grupo)

xtreg zakaibag treated semarab semrel, fe i(group) cluster(group)
scalar b2 = _b[treated]
scalar se2 = _se[treated]
scalar p2 = 2*ttail(e(df_r), abs(_b[treated]/_se[treated]))
scalar g2 = e(N_clust)
est store reg2

*==============================================================================*

* 3) Wild-bootstrap (wild cluster bootstrap restringido, sobre la regresión anterior)

boottest treated, boottype(wild) cluster(group) robust seed(123) nograph
scalar p3 = r(p)

*==============================================================================*

* 4) ARTs (approximate randomization test, Canay, Romano y Shaikh)
* Se estima la regresión dentro de cada cluster (por eso no se pueden incluir
* efectos fijos por grupo) y se testea usando cambios de signo aleatorios de las
* estimaciones de cada cluster.

art zakaibag treated semarab semrel, cluster(group) m(regress) report(treated)
scalar p4 = r(pvalue_joint)
matrix Bc = r(b_cluster)
* estimador del ART: promedio de los coeficientes de treated estimados en cada cluster
scalar b4 = 0
local nb = 0
forvalues g = 1/`=rowsof(Bc)' {
	if Bc[`g',1] != 0 {
		scalar b4 = b4 + Bc[`g',1]
		local ++nb
	}
}
scalar b4 = b4/`nb'

*==============================================================================*

* 5) Exportar

* tabla rtf con las regresiones (columnas 1 y 2) y los p-valores de cada estrategia
est restore reg1
estadd scalar p_val = p1
est store reg1
est restore reg2
estadd scalar p_val = p2
estadd scalar p_wild = p3
estadd scalar p_art = p4
estadd scalar b_art = b4
est store reg2
esttab reg1 reg2 using "$output/Tabla 1.rtf", se replace label noobs keep(treated) ///
	b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) mtitles("Robust SE" "Cluster robust SE") ///
	stats(N N_clust p_val p_wild b_art p_art, fmt(0 0 3 3 4 3) ///
	labels("Observations" "Clusters" "P-value" "Wild bootstrap p-value" "ART estimate" "ART p-value"))

* tabla LaTeX: una columna por estrategia
file open tf using "$output/Tabla 1.tex", write replace
file write tf "{" _n "\begin{tabular}{lcccc}" _n "\toprule" _n
file write tf " & Robust SE & Cluster robust SE & Wild bootstrap & ART \\" _n "\midrule" _n
file write tf "Coeficiente & " %6.4f (b1) " & " %6.4f (b2) " & " %6.4f (b2) " & " %6.4f (b4) " \\" _n
file write tf "Error estándar & " %6.4f (se1) " & " %6.4f (se2) " & -- & -- \\" _n
file write tf "p-valor & " %5.3f (p1) " & " %5.3f (p2) " & " %5.3f (p3) " & " %5.3f (p4) " \\" _n
file write tf "\midrule" _n
file write tf "Efectos fijos por grupo & Sí & Sí & Sí & No \\" _n
file write tf "Clusters & -- & " %2.0f (g2) " & " %2.0f (g2) " & " %2.0f (g2) " \\" _n
file write tf "Observaciones & " %5.0f (n1) " & " %5.0f (n1) " & " %5.0f (n1) " & " %5.0f (n1) " \\" _n
file write tf "\bottomrule" _n "\end{tabular}" _n "}" _n
file close tf
