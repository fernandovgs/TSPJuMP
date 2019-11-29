using JuMP
using Cbc
using Distances
using PyPlot

function main()
    # Reading data to simulate the TSP
    salesman_file = open("pr76.tsp");

    N = 0
    i = 1
	cities = nothing

    while !eof(salesman_file)
    	line = readline(salesman_file)

        info = split(line, ": ")

        # Gets the number of cities
        if (info[1] == "DIMENSION")
        	N = parse(Int, info[2])
        	cities = [Vector{Float64}(undef, 2) for _ in 1:N]
        end

        # Gets the euclidian dots representing a city's position
        if (info[1] == "NODE_COORD_SECTION")
        	for j = 1:N
        		line = readline(salesman_file)

        		ignore, x, y = split(line)
        		cities[j] = [parse(Float64, x), parse(Float64, y)]
        	end
        end

        i += 1
    end
    close(salesman_file)



	# TS definition using Cbc
	salesman = Model(with_optimizer(Cbc.Optimizer))
	
	# Variables
	@variable(salesman, x[1:N,1:N], Bin)
	@variable(salesman, u[1:N])

	# Objective funcion
	@objective(salesman, Min, sum(euclidean(cities[i], cities[j]) * x[i, j]
	    for i in 1:N, j in 1:N if i != j))
	
	# Restrictions to ensure each vertex's exit
	for i in 1:N
	    @constraint(salesman, x[i, i] == 0)
	    @constraint(salesman, sum(x[i,j] for j in 1 : N if i != j ) == 1)
	end
	# Restrictions to ensure each vertex's arrival
	for j in 1:N
	    @constraint(salesman, sum(x[i,j] for i in 1:N if i != j) == 1)
	end
	# Using MTZ formulation to create restrictions that avoids invalid subroutes
	for i in 2:N, j in 2:N
	    @constraint(salesman, u[i] - u[j] + (N * x[i, j]) <= N - 1)
	end
	for i in 2:N
		@constraint(salesman, u[i] >= 1)
		@constraint(salesman, u[i] <= N)
	end
	
	results = optimize!(salesman)


	# objvalue = JuMP.objective_value(salesman)
	# bound = getobjbound(salesman)

	# println("Best inferior boundary: $bound")
	# gap = 100 * (objvalue - bound) / objvalue

	edgeOrigin = []
	edgeDestiny = []

	# #Getting values of x[i,j] to show a solved graph
	# for i in 1:N
	# 	for j in 1:N
	# 		println("Iteracao $i $j")
	# 		if i != j && getvalue(salesman, x[i][j]) > 0.99
	# 			append!(edgeOrigin, cities[i])
	# 			append!(edgeDestiny, cities[j])
	# 		end
	# 	end
	# end

    # Plotting
    clf()
    # plot(edgeOrigin, edgeDestiny, marker = "o", markersize = 6, markercolor = "orange")
    plot(cities, linestyle = "none", marker = "o", markersize = 6, color = "orange")
    xlabel("X")
    ylabel("Y")
    title("Travelling salesman")
    grid("on")
    show()

end

main()


