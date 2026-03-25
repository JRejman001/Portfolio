Projekt_live is the main file that is responsible for passing arguments to optim functions and aquiring the data from which then teh plots are made.
Rosenbrock.m is a file containing a function that is the subject of analisys. If the algorithm requires a gradient function or a hessian then it provides the 
functions for the optimization.
outputFun.m is a file containg a function that is run every iteration of an optimization algorithm. It is responsible for saving the data from the optimization 
funtions, because otherwise the data would be unacsessible.
