$xml_file = [xml](get-content $args[0])
if($args.count -eq 3)
{
    cmd /c "set_var.bat" ($args[1]) ($xml_file.variables.($args[2]))
}
elseif($args.count -eq 4)
{
    cmd /c "set_var.bat" ($args[1]) ($xml_file.variables.($args[2]).($args[3]))
}
elseif($args.count -eq 5)
{
    cmd /c "set_var.bat" ($args[1]) ($xml_file.variables.($args[2]).($args[3]).($args[4]))
}
elseif($args.count -eq 6)
{
    cmd /c "set_var.bat" ($args[1]) ($xml_file.variables.($args[2]).($args[3]).($args[4]).($args[5]))
}