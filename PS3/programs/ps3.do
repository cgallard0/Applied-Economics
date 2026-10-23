/*******************************************************************************
							    Problem Set 3

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
foreach pkg in estout asdoc {
	cap which `pkg'
	if _rc ssc install `pkg'
}

*==============================================================================*
* EJERCICIO 1 
*==============================================================================*

set obs 100
set seed 1233

gen Intelligence = int(rnormal(100,20))
gen A = int(rnormal(10,3))
gen B = int(rnormal(5,1))
gen u = int(rnormal(0,1))
gen Wage = 3*Intelligence + A + 2*B + u

reg Wage Intelligence A B
est store reg_base

*______________________________________(1)______________________________________*

clear
set obs 1000 // Aumentamos el tamaño muestral a 1000
set seed 1233

gen Intelligence = int(rnormal(100,20))
gen A = int(rnormal(10,3))
gen B = int(rnormal(5,1))
gen u = int(rnormal(0,1))
gen Wage = 3*Intelligence + A + 2*B + u

reg Wage Intelligence A B
est store reg_1
esttab reg_base reg_1 using "$output/Tabla 1.rtf", replace se label ///
addnotes("Model 1 is the original regression. Model 2 is the regression with an increased sample size.")


esttab reg_base reg_1 using "$output/Tabla 1.tex", replace se label booktabs nonotes
*______________________________________(2)______________________________________*

clear
set obs 100
set seed 1233

gen Intelligence = int(rnormal(100,20))
gen A = int(rnormal(10,3))
gen B = int(rnormal(5,1))
gen u = int(rnormal(0,10)) // Aumentamos la varianza del término de error
gen Wage = 3*Intelligence + A + 2*B + u

reg Wage Intelligence A B
est store reg_2
esttab reg_base reg_2 using "$output/Tabla 2.rtf", replace se label ///
addnotes("Model 1 is the original regression. Model 2 is the regression with increased variance in the error term.")


esttab reg_base reg_2 using "$output/Tabla 2.tex", replace se label booktabs nonotes
*______________________________________(3)______________________________________*

clear
set obs 100
set seed 1233

gen Intelligence = int(rnormal(100,50)) // Aumentamos la varianza de intelligence
gen A = int(rnormal(10,3))
gen B = int(rnormal(5,1))
gen u = int(rnormal(0,1))
gen Wage = 3*Intelligence + A + 2*B + u

reg Wage Intelligence A B
est store reg_3
esttab reg_base reg_3 using "$output/Tabla 3.rtf", replace se label ///
addnotes("Model 1 is the original regression. Model 2 is the regression with increased variance in Intelligence.")


esttab reg_base reg_3 using "$output/Tabla 3.tex", replace se label booktabs nonotes
*______________________________________(4)______________________________________*

*Usando el modelo original
clear
set obs 100
set seed 1233

gen Intelligence = int(rnormal(100,20))
gen A = int(rnormal(10,3))
gen B = int(rnormal(5,1))
gen u = int(rnormal(0,1))
gen Wage = 3*Intelligence + A + 2*B + u

reg Wage Intelligence A B
predict Residuals, residuals
estpost tabstat Residuals, listwise /// 
stats(sum)
esttab using "$output/Tabla 4.rtf", cells("sum") collabels("Sum") ///
label replace
esttab using "$output/Tabla 4.tex", cells("sum(fmt(%12.2e))") collabels("Suma") ///
label replace booktabs nonumber noobs

*______________________________________(5)______________________________________*

asdoc pwcorr Residuals Intelligence A B, save($output/Tabla 5.rtf) replace
* versión LaTeX de la matriz de correlaciones
quietly correlate Residuals Intelligence A B
matrix C = r(C)
esttab matrix(C, fmt(3)) using "$output/Tabla 5.tex", replace booktabs nomtitles

*______________________________________(6)______________________________________*

clear
set obs 100
set seed 1233

gen Intelligence = int(rnormal(100,20))
gen Education = Intelligence + rnormal(0,1) // Genero la var education con una alta correlación con intelligence
corr Intelligence Education
gen A = int(rnormal(10,3))
gen B = int(rnormal(5,1))
gen u = int(rnormal(0,1))
gen Wage = 3*Intelligence + A + 2*B + u

reg Wage Intelligence Education A B
est store reg_6
esttab reg_base reg_6 using "$output/Tabla 6.rtf", replace se label ///
addnotes("Model 1 is the original regression. Model 2 is the regression with high multicollinearity as it adds the variable Education.") 


esttab reg_base reg_6 using "$output/Tabla 6.tex", replace se label booktabs nonotes
*______________________________________(7)______________________________________*

clear
set obs 100
set seed 1233

gen intelligence = int(rnormal(100,20))
gen A = int(rnormal(10,3))
gen B = int(rnormal(5,1))
gen u = int(rnormal(0,1))
gen Wage = 3*intelligence + A + 2*B + u

*Error no aleatorio en X
gen intelligence_error = intelligence + 5 // Agregamos error no aleatorio en X
preserve
rename intelligence_error Intelligence
reg Wage Intelligence A B
est store reg_7_1
restore

*Error aleatorio en X 
gen intelligence_random_error = intelligence + rnormal(0,5) // Agregamos error aleatorio en X
preserve
rename intelligence_random_error Intelligence
reg Wage Intelligence A B
est store reg_7_2
restore

esttab reg_base reg_7_1 reg_7_2 using "$output/Tabla 7.rtf", replace se label ///
addnotes("Model 1 is the original regression. Model 2 is the regression with a non-random error in Intelligence. Model 3 is the regression with a random error in Intelligence.")


esttab reg_base reg_7_1 reg_7_2 using "$output/Tabla 7.tex", replace se label booktabs nonotes
*______________________________________(8)______________________________________*

clear
set obs 100
set seed 1233

gen Intelligence = int(rnormal(100,20))
gen A = int(rnormal(10,3))
gen B = int(rnormal(5,1))
gen u = int(rnormal(0,1))
gen wage = 3*Intelligence + A + 2*B + u

// Error no aleatorio en Y
gen wage_nonrandom_error = wage + 10 // Agregamos error no aleatorio en Y
label var wage_nonrandom_error "Wage (Non-Random Error)"
reg wage_nonrandom_error Intelligence A B
est store reg_8_1

// Error aleatorio en Y
gen wage_random_error = wage + rnormal(0,5) // Agregamos error aleatorio en Y
label var wage_random_error "Wage (Random Error)"
reg wage_random_error Intelligence A B
est store reg_8_2

esttab reg_base reg_8_1 reg_8_2 using "$output/Tabla 8.rtf", replace se label ///
addnotes("Model 1 is the original regression. Model 2 is the regression with a non-random error in Y. Model 3 is the regression with a random error in Y.")

esttab reg_base reg_8_1 reg_8_2 using "$output/Tabla 8.tex", replace se label booktabs nonotes
