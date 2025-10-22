Set UAC = CreateObject("Shell.Application")
Set args = WScript.Arguments

If args.Count = 0 Then
    WScript.Echo "Usage: elevate.vbs <path_to_file_to_run> [arguments]"
    WScript.Quit
End If

scriptPath = args(0)
scriptArgs = ""

If args.Count > 1 Then
    For i = 1 To args.Count - 1
        scriptArgs = scriptArgs & " " & args(i)
    Next
End If

UAC.ShellExecute "cmd.exe", "/c """ & scriptPath & """ " & scriptArgs, "", "runas", 1
