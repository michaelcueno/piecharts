require( "./validation")
require( "./stats")
require( "./app_database")

LIMIT = 40  # Modify this to set how many values are listed in under sexp, function and keyword lists
ERRORS = false  # suppress errors

#=========================================================== MAIN METHOD ======================================#
data = Stats.new
path = Dir["/homes/mcueno/apps/*"]
dumpFile = File.new("dump.txt", 'w')

# Main loop: For each rails app do ...
path.each do |path| 

  data.plus_one_app
  app_name = path.split("/")[0]
  
  if File.exists?(path + "/log/rsbc/validator_types") and File.exists?(path + "/log/rsbc/rsbc.log") then
    data.plus_one_custom

    # Import validator_types and rsbc.log into local Files
    types = File.open( path + "/log/rsbc/validator_types", 'r')
    rsbc = File.open( path + "/log/rsbc/rsbc.log", 'r')


    # Init the data with the validators by parsing the vlaidator_types.log

    types.each_line {|line|
      array = line.split(" ")
      id = array[0]
      case array[2]
      when "association" then data.plus_one("association")
      when "builtin" then data.plus_one("builtin"); data.classify_builtin(array[1])
      when "unknown" then data.plus_one("unknown")
      when "validator" then data.plus_one("validator"); data.add(array[0]); data.add_app(array[0])
      when "model_defined" then data.plus_one("model_defined"); data.add(array[0]); data.add_app(array[0])
      end
      if array[1] == "gem" then data.plus_one("gem"); data.add(array[0]); data.add_app(array[0]) end
      
      # Dump validator types to file
      File.open("dump.txt", 'a') { |f| f.write(line) } 
    }

    # Parse rsbc.log and add to validations appropriately
    rsbc.each_line {|line|
      data.parse_rsbc(line)
    }




  else 
    if ERRORS then puts "ERROR: rake rsbc failed on   " + path.to_s end
  end
end

data.crunch

#============================ Interactive portion of program =========================
puts "type help for commands, 'q' to quit"
print "enter command: "
line = gets.chomp.split(" ")
menu = line[0]
while !(menu == "q" || menu == "quit" || menu == "exit")
  case menu
  when 'help' then 
    puts "stats       print out general stats about all validations found"
    puts "builtins    print out info on the builtin validations"
    puts "successes   print info on validations that succeeded"
    puts "failures    print info on validations that did not pass"
    puts "inspect     inspect a single validation, Input format: App~Model~validation "
    puts "list        list all apps, then enter app name to list models within, then enter model to list validations"
    puts "query       search validations based on error type"
    puts "priority    list the blocks to fix in order of the number of blocks that will successfully translate"
    puts "               Block id is givien as: App_name ~ Model_name ~ Validaiton_name ~ block_num"
    puts " **Note: Change LIMIT at the top of piecharts.rb to list more values for all commands"

  when 'stats' then data.output_stats 
  when '1' then data.output_keyword
  when '2' then data.output_function
  when '3' then data.output_sexp
  when '4' then data.output_method
  when '5' then data.output_database 
  when '6' then data.output_unknown
  when 'builtins' then data.output_builtins
  when 'blocks' then data.output_block_stats
  when 'successes' then 
    puts "============ Successful Validation Id's ============="
    successes = data.get_successful
    puts successes 
  when 'failures' then 
    puts "============ Failed Validation Id's ============="
    failures = data.get_failures
    puts failures 
  when 'inspect' then data.inspect(line[1]) 
  when 'list' then data.list_apps 
  when 'query' 
    print "Enter Error type: "
    error = gets.chomp.upcase.to_sym
    print "Enter value: " 
    value = gets.chomp
    data.query(error, value)
  when 'blocks-success' then data.output_successful_blocks
  when 'blocks-semantic' then data.output_semantic 
  when 'priority' then data.output_priority
  when 'plato' then data.output_plato_only
    
  end
  print "enter command: "
  line = gets.chomp.split(" ")
  menu = line[0]
end
