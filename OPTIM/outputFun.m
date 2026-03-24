function stop = outputFun(x, optimValues, state)
    persistent history_x history_f

    stop = false;

    switch state
        case 'init'
            % inicjalizacja pamięci
            history_x = [];
            history_f = [];

        case 'iter'
            % zapis punktu (wiersz)
            history_x = [history_x; x(:)'];

            % zapis wartości funkcji
            history_f = [history_f; optimValues.fval];

        case 'done'
            % zapis do workspace (po zakończeniu)
            assignin('base', 'history_x', history_x);
            assignin('base', 'history_f', history_f);
    end
end