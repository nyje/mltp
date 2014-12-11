local output = io.open("skinlist.txt", "w")
os.execute([[for file in *; do mv "$file" `echo $file | tr ' ' '_'` ; done]])--sloppyness
os.execute([[for file in *; do mv "$file" `echo $file | tr '(' '_'` ; done]])
os.execute([[for file in *; do mv "$file" `echo $file | tr ')' '_'` ; done]])
local filelist = io.popen("ls")

for line in filelist:lines() do
  if string.find(line:lower(), "png") then
    print(line)
    local cmd = string.gsub([[convert "LINE"[1x1+0+0] -format "%[fx:int(255*r)],%[fx:int(255*g)],%[fx:int(255*b)]" info:]], "LINE", line)
    local color = io.popen(cmd):read()
    local type = nil
    print(color)
    if color == "249,177,49" or "208,204,207" then
      type = "earth"
    elseif color == "136,202,240" or "123,189,240" then
      type = "pegasus"
    elseif color == "209,159,228" then
      type = "unicorn"
    elseif color == "254,249,252" or  "40,43,41" then
      type = "alicorn"
    else 
      type = "other"
      print("pony type code error");
      break
    end
    output:write(line .. " " .. type .. "\n")
  end
end

filelist:close()
output:close()
