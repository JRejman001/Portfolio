function [fval, grad, H] = Rosenbrock(x)
    a = 1.5;
    b = -1;
    fval = (1 - x(1) + 1.5).^2 + 100 .* (x(2) + 1 - x(1).^2).^2;
    if nargout > 1 % gradient required
        grad = [2.*x(1) - 400.*x(1).*(-x(1).^2 + x(2) + 1) - 5;
            -200.*x(1).^2 + 200.*x(2) + 200];
    end
    if nargout > 2 % Hessian required
        H = [1200.*x(1).^2 - 400.*x(2) - 398, -400.*x(1);
            -400.*x(1), 200];
    end
end