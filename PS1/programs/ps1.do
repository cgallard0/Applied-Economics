/*******************************************************************************
							    Problem Set 1

                          Universidad de San Andrés
                              Economía Aplicada
									2024							           
*******************************************************************************/

clear all
set more off

* directorio: completar con la ruta a la carpeta del problem set
global main ""
global input "$main/input"
global output "$main/output"

* paquetes necesarios (se instalan solo si no están)
foreach pkg in estout outreg2 mdesc {
	cap which `pkg'
	if _rc ssc install `pkg'
}

* import data
use "$input/data_russia.dta", clear

*==============================================================================*

* 1) clean data
* covertimos las variables sex y obese en binarias numericas, reemplazando el texto
rename sex sex1
gen sex = .
replace sex = 1 if sex1 == "female"
replace sex = 0 if sex1 == "male"

replace sex1 = "Female" if sex1 == "female"
replace sex1 = "Male" if sex1 == "male"
label var sex1 "Sex"

gen obesity = .
replace obesity = 1 if obese == "This person is obese"
replace obesity = 0 if obese == "This person is not obese"
drop obese

* removemos el texto de las variables hipsiz y totexpr para que sean numericas
replace hipsiz = subinstr(hipsiz, "hip circumference ", "", .)
* los valores faltantes vienen como "," y se pasan a vacío antes del destring
replace hipsiz = "" if hipsiz == ","
destring hipsiz, replace dpcomma

replace totexpr = subinstr(totexpr, "Total expenditures ", "", .)
replace totexpr = "" if totexpr == ","
destring totexpr, replace dpcomma

* loop para corregir otros errores
local vars econrk powrnk resprk satlif satecc highsc belief monage cmedin hprblm hosl3m wtchng evalhl operat hattac smokes alclmo waistc hhpres tincm_r geo work0 work1 work2 ortho marsta1 marsta2 marsta3 marsta4
foreach var of local vars {
    replace `var' = "1" if `var' == "one"
    replace `var' = "2" if `var' == "two"
    replace `var' = "3" if `var' == "three"
    replace `var' = "4" if `var' == "four"
    replace `var' = "5" if `var' == "five"
	replace `var' = "1" if `var' == "Smokes"
	replace `var' = "." if `var' == ","
	replace `var' = "." if `var' == ".b"
    destring `var', replace
}

destring tincm_r, replace dpcomma

replace htself = . if htself == .b

*==============================================================================*

* 2) missing data
mdesc

*==============================================================================*

* 3) data anomalies
* usamos summarize para revisar que los minimos y maximos de las variables tengan sentido
summarize

* sacamos gastos/ingresos negativos y gastos mayores al ingreso
replace totexpr = . if totexpr < 0
replace tincm_r = . if tincm_r < 0
replace totexpr = . if totexpr > tincm_r

*==============================================================================*

* 4) data organization
* ordenamos de la forma requerida
order id site sex
gsort - totexpr

*==============================================================================*

* 5) descriptive statistics
* creamos la variable age, edad en años
gen age = .
replace age = floor(monage / 12)
drop monage

label var age "Age in Years"
label var sex "Female"

* creamos y exportamos una tabla
* cada variable se resume con todas sus observaciones válidas y se reporta el N
estpost summarize sex age satlif waistc hipsiz totexpr
esttab using "$output/Tabla 1 - Ejercicio 5.rtf", cells("count mean sd min max") ///
collabels("N" "Mean" "SD" "Min" "Max") nomtitle nonumber noobs replace label
esttab using "$output/Tabla 1 - Ejercicio 5.tex", ///
cells("count(fmt(%9.0fc)) mean(fmt(%9.2f)) sd(fmt(%9.2f)) min(fmt(%9.2f)) max(fmt(%9.2f))") ///
collabels("N" "Media" "Desvío" "Mín." "Máx.") nomtitle nonumber noobs replace label booktabs

*==============================================================================*

* 6) box plot and ttest
* creamos un box plot para comparar hipsiz entre hombres y mujeres
graph box hipsiz, over(sex, relabel(1 "Male" 2 "Female")) ///
	title("Hip Circumference by Sex", color(black)) ytitle("Hip Circumference (cm)")
graph export "$output/Figura 1 - Ejercicio 6.png", replace

* usamos ttest para testear la diferencia de medias de hipsiz entre hombres y mujeres
estpost ttest hipsiz, by(sex1)
esttab using "$output/Tabla 2 - Ejercicio 6.rtf", replace label
* versión LaTeX con las medias de cada grupo (diferencia = Female - Male)
esttab using "$output/Tabla 2 - Ejercicio 6.tex", ///
cells("mu_1(fmt(2)) mu_2(fmt(2)) b(fmt(2) star) t(fmt(2)) p(fmt(3))") ///
collabels("Mujeres" "Hombres" "Diferencia" "t" "p-valor") ///
nomtitle nonumber noobs replace label booktabs star(* 0.10 ** 0.05 *** 0.01)

*==============================================================================*

* 7) regression
* generamos marstat1 que agrupa marsta1 y marsta2, personas que estan en una relación 
* marstat1 = 1 si está casado/a o convive
gen marstat1 = (marsta1 == 1 | marsta2 == 1) if !missing(marsta1, marsta2)
label var marstat1 "In a Relationship"

* generamos marstat2 que agrupa marsta3 y marsta4, personas que no estan en una relación 
* marstat2 = 1 si está divorciado/a o es viudo/a
* (los solteros que nunca se casaron, con marsta1-marsta4 = 0, quedan en 0 en ambas)
gen marstat2 = (marsta3 == 1 | marsta4 == 1) if !missing(marsta3, marsta4)
label var marstat2 "Divorced or Widowed"

* los histogramas dobles requieren Stata 15 en adelante para que se vean bien los colores
* histogramas con el % de cada grupo en cada nivel de satisfacción
graph twoway (histogram satlif if marstat1 == 1, discrete percent gap(20) color(green%30)) /// 
             (histogram satlif if marstat2 == 1, discrete percent gap(20) color(red%30)), ///
             legend(label(1 "Married or Living Together") label(2 "Divorced or Widowed")) ///
			 title("Distribution of Satisfaction with Life", color(black)) ///
			 subtitle("Married or Living Together vs Widowed or Divorced") ///
			 ytitle("Percent") xtitle("Satisfaction with Life") ///
			 xlabel(1 "1 (Insatisfecho)" 2 "2" 3 "3" 4 "4" 5 "5 (Satisfecho)")
graph export "$output/Figura 2 - Ejercicio 7.png", replace

graph twoway (histogram satlif if cmedin == 1, discrete percent gap(20) color(green%30)) /// 
             (histogram satlif if cmedin == 0, discrete percent gap(20) color(red%30)), ///
             legend(label(1 "Health Insurance") label(2 "No Health Insurance")) ///
			 title("Distribution of Satisfaction with Life", color(black)) ///
			 subtitle("Health Insurance vs No Health Insurance") ///
			 ytitle("Percent") xtitle("Satisfaction with Life") ///
			 xlabel(1 "1 (Insatisfecho)" 2 "2" 3 "3" 4 "4" 5 "5 (Satisfecho)")
graph export "$output/Figura 3 - Ejercicio 7.png", replace

* generamos econ, una variable para ver la interacción de econrk y satecc
gen econ = .
replace econ = econrk*satecc
label var econ "Economic Rank x Satisfaction with Economic Condition"

* generamos age2, la edad al cuadrado
gen age2 = .
replace age2 = age*age
label var age2 "Age Squared"

* generamos ln_income, el logaritmo natural del ingreso
gen ln_income = .
replace ln_income = ln(tincm_r)
label var ln_income "Natural Log of Income"

label var hprblm "Health Problems in last 30 days"

* categorías omitidas: work1 (leaving work) y soltero/a (marsta1-marsta4 = 0)

* regresión primer modelo
eststo clear
eststo m1: regress satlif age age2 sex height ln_income work0 work2 marsta1 marsta2 marsta3 marsta4 econrk hprblm
outreg2 using "$output/Tabla 3 - Ejercicio 7.doc", replace label

* regresión segundo modelo
* el modelo incluye la interacción econ = econrk*satecc y sus dos efectos principales
eststo m2: regress satlif age age2 sex htself ln_income work0 work2 econrk satecc econ evalhl cmedin
outreg2 using "$output/Tabla 4 - Ejercicio 7.doc", replace label

* ambas especificaciones en una tabla LaTeX
esttab m1 m2 using "$output/Tabla 3 y 4 - Ejercicio 7.tex", replace label booktabs ///
b(a3) se(a3) star(* 0.10 ** 0.05 *** 0.01) r2 nonotes ///
mtitles("Modelo 1" "Modelo 2") order(age age2 sex height htself ln_income work0 work2 ///
marsta1 marsta2 marsta3 marsta4 econrk satecc econ hprblm evalhl cmedin)

*==============================================================================*
