# Load Jlpigraf parallel to other packages for development
# current directory: "Jlpigraf.jl/examples"

using Pkg, Revise
Pkg.activate(".") 
Pkg.develop("..")

using Jlpigraf

Jlpigraf.version # get version info
