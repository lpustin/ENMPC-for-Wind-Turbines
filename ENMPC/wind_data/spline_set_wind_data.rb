#--------------------------------------------------------------------------#
#   ____        _ _               ____ _
#  / ___| _ __ | (_)_ __   ___   / ___| | __ _ ___ ___
#  \___ \| '_ \| | | '_ \ / _ \ | |   | |/ _` / __/ __|
#   ___) | |_) | | | | | |  __/ | |___| | (_| \__ \__ \
#  |____/| .__/|_|_|_| |_|\___|  \____|_|\__,_|___/___/
#        |_|
#   ____       _
#  / ___|  ___| |_ _   _ _ __
#  \___ \ / _ \ __| | | | '_ \
#   ___) |  __/ |_| |_| | |_) |
#  |____/ \___|\__|\__,_| .__/
#                       |_|
#--------------------------------------------------------------------------#
# possible choices

include Mechatronix

Circuit_Vars, Circuit_Table = Utils::read_from_table(File.expand_path("../wind_data.txt", __FILE__))

# user defined values
#puts Circuit_Table["speed"]

mechatronix do |data|

  data.SplineWindSpeed = {
    :spline_type  => [
      "cubic",
    ],
    :headers => [
      "speed"
    ],
    :boundary => [
      { :closed => false, :extend => true, :extend_constant => true }
    ],
    :xdata => Circuit_Table["time"], 
    :ydata => [
      Circuit_Table["speed"],
    ]
  }
  #p data.SplineSet[:data]

end

#EOF
