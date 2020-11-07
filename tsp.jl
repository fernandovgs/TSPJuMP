using JuMP
using Cbc
using Distances
using PyPlot

function main()
    # Reading data to simulate the TSP
    salesman_file = open("ulysses16.tsp");

    N = 0
    i = 1
	cities = nothing

    while !eof(salesman_file)
		line = readline(salesman_file)
        info = ""
		println(sizeof(line))

		if sizeof(line) != 4
			if line[1:5] == "NAME:"
				info = split(line, ": ")
			else
				info = split(line, " : ")
			end
		end

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

	# Objective function
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
	print("optimizing")
	results = optimize!(salesman)

	#Getting values of x[i,j] to show a solved graph
	edgeOrigin = [Vector{Float64}(undef, 2) for _ in 1:N]
	edgeDestiny = [Vector{Float64}(undef, 2) for _ in 1:N]
	j = 1
	k = 1
	for i in 1:(N*N)
		if j != k && getvalue(x[i]) > 0.99
			edgeOrigin[j] = cities[j]
			edgeDestiny[j] = cities[k]
			# append!(edgeOrigin, cities[j])
			# append!(edgeDestiny, cities[k])
		end

		if k == N
			k = 1
			j += 1
		else
			k += 1
		end
	end

	edgesX = 0
	edgesY = 0


    # Plotting
	clf()
	# points
	for i in 1:N
		plot(cities[i][1], cities[i][2], linestyle = "none", marker = "o", markersize = 6, color = "orange")
	end

	# Lines
	for i in 1:N
		edgesX = [edgeOrigin[i][1], edgeDestiny[i][1]]
		edgesY = [edgeOrigin[i][2], edgeDestiny[i][2]]

		plot(edgesX, edgesY, color = "blue")
	end
    xlabel("X")
    ylabel("Y")
    title("Travelling salesman")
    grid("on")
    show()

end

main()
