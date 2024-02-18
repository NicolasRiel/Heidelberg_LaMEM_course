# list of used Julia packages
using Plots
using CurveFit


"""
    sum_iteration(n_iteration)
    
        where n_iteration is an integer
        return sum(n_iteration)
"""
function sum_iteration(n_iteration=10)
    total = 0.0

    for i=1:n_iteration
        total = total + 1
    end

    return total
end


"""
while_loop(n_iteration,M)
    
        where n_iteration is an integer, M is an integer
        return M + sum( (n_iteration-1)*10 )
"""
function while_loop(n_iteration=10,M=50)

    i=1
    while i < n_iteration
        M += 10
        i += 1
        print("i = $i, M = $M\n")
    end

    return M
end



"""
    check_M(M)
        where...

"""
function check_M(M)

    if M < 10
        M += 25
    elseif M == 10
        M = M^2
    else
        M = 0
    end

    return M
end



"""
    plot_square()
        simply plots the square function between -10 and 10

"""
function plot_square()

    x  =  -10:0.1:10
    y  = x.^2
    yp = x.^3

    plot(x,y)
    plot!(x,yp)
    title!("Square function")
    xlabel!("x")
    ylabel!("x²")
end


"""
    exercice_1(M, dM, n_years)
        Assumes we have an initial amount of money on the bank (M=1000) 
            and each year we save some money (dM=100)
        M is starting_money
        dM is yearly_savings
        n_years is the number fo years of savings
"""
function exercice_1(M=1000, dM=10, n_years=25)

    Mtotal = zeros(n_years)

    for i=1:n_years
        M = M + dM;
        Mtotal[i] = M
    end

    plot(Mtotal)
    title!("Money trend in the bank")
    xlabel!("time (years)")
    ylabel!("money \$")
end




"""
    exercice_1b(M, dM, n_years, interest_rate)
        Assumes we have an initial amount of money on the bank (M=1000) 
            and each year we save some money (dM=100)
        M is starting_money
        dM is yearly_savings
        n_years is the number fo years of savings
        interest_rate is the interest rate of the bank in in %
"""
function exercice_1b(M, dM, n_years, interest_rate)

    Mtotal = zeros(n_years)

    for i=1:n_years
        M = M + M*interest_rate/100
        M = M + dM;
        Mtotal[i] = M
    end

    plot(Mtotal)
    title!("Money trend in the bank \n (interested rate of $interest_rate %)")
    xlabel!("time (years)")
    ylabel!("money \$")
end




"""
    exercice_1c(M, dM, n_years, interest_rate)
        Assumes we have an initial amount of money on the bank (M=1000) 
            and each year we save some money (dM=100)
        M is starting_money
        dM is yearly_savings
        n_years is the number fo years of savings
        interest_rate is the interest rate of the bank in in %
"""
function exercice_1c(M, dM, n_years, interest_rate)

    Mtotal = zeros(n_years)

    for i=1:n_years
        M = M + M*interest_rate/100
        M = M + dM;
        Mtotal[i] = M
    end

    plot(Mtotal, lc=:black, lw=2)
    scatter!(Mtotal, lc=:red, ms=10, ma=0.8)
    title!("Money trend in the bank \n (interested rate of $interest_rate %)")
    xlabel!("time (years)")
    ylabel!("money \$")
end



"""
    exercice_1c(M, dM, n_years, interest_rate)
        Assumes we have an initial amount of money on the bank (M=1000) 
            and each year we save some money (dM=100)
        M is starting_money
        dM is yearly_savings
        n_years is the number fo years of savings
        interest_rate is the interest rate of the bank in in %
"""
function exercice_1d(M=1000, dM=100, n_years=25, interest_rate=10)

    Mtotal = zeros(n_years)


    for i=1:n_years
        M = M + M*interest_rate/100
        M = M + dM;
        Mtotal[i] = M
    end


    x = 1:1:n_years
    fit = curve_fit(Polynomial, x, Mtotal, 2)
    Mtotal_fitted = fit.(x) 

    fit3 = curve_fit(Polynomial, x, Mtotal, 3)
    Mtotal_fitted3 = fit3.(x) 


    # plot(Mtotal, lc=:black, lw=1, label="Curve")
    scatter(Mtotal, lc=:red, ms=2, ma=0.8, label="Curve points")

    plot!(x,Mtotal_fitted, lc=:green, lw=1, label="Fitted Curve n=2")
    plot!(x,Mtotal_fitted3, lc=:red, lw=1, label="Fitted Curve n=3")
    # scatter!(x,Mtotal_fitted, lc=:green, ms=2, ma=0.8, label="Fitted Curve points")


    title!("Money trend in the bank \n (interested rate of $interest_rate %) \n Fitting tests")
    xlabel!("time (years)")
    ylabel!("money \$")
end


