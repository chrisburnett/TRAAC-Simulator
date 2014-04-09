require 'csv'
require 'rubygems'
require 'descriptive_statistics'

class Plotter

  def self.datasets_to_columns(datasets)
    # need to collate the results from each run and timestep, and
    # average
    columns = []
    # columns for the error bars
    error_columns = []
    # first collate
    datasets.each do |name, runs|
      data = []
      errors = []
      # for this condition, go through each time step
      # average the result for each run and add to data
      # for each time step:
      data << name
      runs[0].size.times do |i| 
        error = []
        # sum the result from all runs
        sum = 0.0
        runs.each do |run| 
          sum += run[i] 
          error << run[i]
        end
        # add the average for this timestep to the data
        data << sum / runs.size.to_f
        errors << error.standard_deviation
      end
      # add the data for this condition to the columns
      columns << data
      error_columns << errors
    end
    [columns, error_columns]
  end
  

  def self.plot_results
    commands = %Q(
set terminal postscript
set output "resultsys.eps"
set xrange [0:500]
set yrange [-0.05:0.2]
set xlabel '{/Helvetica-Oblique time}'
set ylabel '{/Helvetica-Oblique owner utility}'
set datafile separator ","
plot for [i=1:3] "results.csv" using i with lines title columnheader

)
    IO.popen("gnuplot", "w") { |io| io.puts commands }
  end


  def self.writeout_results(conditions)
    columns, error_columns = datasets_to_columns(conditions)
    
    CSV.open("results.csv", "wb") do |csv|      
      columns[0].size.times do |i|
        row = []
        columns.each { |col| row << col[i] }
        csv << row
      end
    end

    CSV.open("errors.csv", "wb") do |csv| 
      error_columns[0].size.times do |i| 
        row = []
        error_columns.each { |col| row << col[i] }
        csv << row  
      end
    end
  end
end
