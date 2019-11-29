using JuMP
using GLPK
using Distances

function main()
    # Reading data to simulate the TSP
    salesman_file = open("burma14.tsp");

    N = 0
    i = 1
	cities = nothing

    while !eof(salesman_file)
    	line = readline(salesman_file)
    	println(line)

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

        		println(cities[j])
        	end
        end

        i += 1
    end
    close(salesman_file)

	# TS definition using GLPK
	caixeiro = Model(with_optimizer(GLPK.Optimizer))
	
	# Variables
	@variable(caixeiro, x[1:N,1:N], Bin)
	@variable(caixeiro, u[1:N])

	# Objective funcion
	@objective(caixeiro, Min, sum(euclidean(cities[i], cities[j]) * x[i, j]
	    for i in 1:N, j in 1:N if i != j))
	
	# Restrictions to ensure each vertex's exit
	for i in 1:N
	    @constraint(caixeiro, x[i, i] == 0)
	    @constraint(caixeiro, sum(x[i,j] for j in 1 : N if i != j ) == 1)
	end
	# Restrictions to ensure each vertex's arrival
	for j in 1:N
	    @constraint(caixeiro, sum(x[i,j] for i in 1:N if i != j) == 1)
	end
	# Using MTZ formulation to create restrictions that avoids invalid subroutes
	for i in 2:N, j in 2:N
	    @constraint(caixeiro, u[i] - u[j] + (N * x[i, j]) <= N - 1)
	end
	for i in 2:N
		@constraint(caixeiro, u[i] >= 1)
		@constraint(caixeiro, u[i] <= N)
	end
	
	print(caixeiro)

end

main()


