function [fval, grad, H] = Rosenbrock(x)
    a = 1.5;
    b = -1;
    x = x';
    fval = (1 - x(1) + 1.5)^2 + 100 * (x(2) + 1 - (x(1) - 1.5)^2)^2;
    if nargout > 1 % gradient required
        t1 = 2*x(1) - 200*(2*x(1) - 3)*(x(2) - (x(1) - 3/2)^2 + 1) -5;
        t2 = 200*x(2) - 200*(x(1) - 3/2)^2 + 200;
        grad = [t1;
            t2];
    end
    if nargout > 2 % Hessian required
        H = [1200*x(1).^2 - 3600*x(1) - 400*x(2) + 2302, 600 - 400*x(1);
            600 - 400*x(1), 200];
    end
end