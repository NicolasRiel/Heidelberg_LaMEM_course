# My first script
using Plots

function rosenbrock(x,y; a=1,b=100)
    xt = x'     # transpose  
    f  = (a .- xt).^2 .+ b.*(y .- xt.^2).^2
    return f
end


x = range(-2.0,2.0,length=50)
y = range(-1.0,1.5,length=50)
f = rosenbrock(x,y)

# Create a contourplot
contour(x,y,f, levels=0:10:200, fill=true, 
        xlabel="X", ylabel="y", title="rosenbrock", 
        color=:roma, clim=(1,200))
