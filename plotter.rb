 require 'csv'
require_relative 'parameters'

class Plotter

  def self.datasets_to_columns(datasets)
    # need to collate the results from each run and timestep, and
    # average
    columns = []
    # first collate
    datasets.each do |name, runs|
      data = []
      # for this condition, go through each time step
      # average the result for each run and add to data
      # for each time step:
      data << name
      runs[0].size.times do |i| 
        # sum the result from all runs
        sum = 0.0
        runs.each { |run| sum += run[i] }
        # add the average for this timestep to the data
        data << sum / runs.size.to_f
      end
      # add the data for this condition to the columns
      columns << data
    end
    columns
  end
  

  def self.plot_results
    commands = %Q(
set terminal postscript
set output "results.eps"
set xrange [0:#{Parameters::TIME_STEPS}]
set yrange [-0.05:0.2]
set datafile separator ","
plot for [i=1:3] "results.csv" using i with lines title columnheader

)
    IO.popen("gnuplot", "w") { |io| io.puts commands }
  end


  def self.writeout_results(conditions)
    columns = datasets_to_columns(conditions)
    
    CSV.open("results.csv", "wb") do |csv|      
      columns[0].size.times do |i|
        row = []
        columns.each { |col| row << col[i] }
        csv << row
      end
    end
  end
  

end
