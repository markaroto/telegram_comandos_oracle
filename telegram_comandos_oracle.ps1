function send_telegram(){
    param(
    [string]$mensagem
    )
    $url="https://api.telegram.org/bot$token/sendMessage?chat_id=$idchat&text=$mensagem"
    $webSend=New-Object System.Net.WebClient
    Start-Sleep -Milliseconds 4000
	#Proxy
	#$proxy = New-Object System.Net.WebProxy(${proxyCaminho})
	#$proxy.useDefaultCredentials = $true
	#$webSend.Proxy=$proxy
    $exit = $webSend.DownloadString($url)
    Remove-Variable -Name webSend  
}
function command_sql(){
	param(
	[string]$comando
	)
	write-host $comando
    $sqlQuery = @"
		set NewPage none
		set heading off
		set feedback off
		${comando}
		exit
"@
	$retorno = $sqlQuery | sqlplus -s ${userOracle}/${senhaOracle}@${instancia}  
	send_telegram -mensagem $retorno
	Start-Sleep -Milliseconds 1000
}
function get_telegram(){
	do{			
        Start-Sleep -Milliseconds 3000
        #write-host "ok"
        $web= New-Object System.Net.WebClient
		$web.Headers.Add("user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)");
		#Proxy
		#$proxy = New-Object System.Net.WebProxy(${proxyCaminho})
		#$proxy.useDefaultCredentials = $true
		#$web.Proxy=$proxy
		#coleta dados.
        $resultados = $web.DownloadString("https://api.telegram.org/bot$token/getUpdates")
		$resultados=($resultados | ConvertFrom-Json).result
        if($sair -ne 0){
			$sair=1
		}
		$txt_id="${caminhoArquivo}\id.txt"
		$arquivo= Get-Content $txt_id		
		foreach ( $resultado in $resultados){
			if(!($arquivo | Where-Object {$_ -match $resultado.update_id})){
				#Gravar o arquivo de ID
				Write-Output  ($resultado.update_id).ToString() | Out-File -Append $txt_id
				#Validação do ID do grupo
				if($resultado.message.chat.id -eq ${idchat}){
					#Conexão com banco é necessario informar a instancia.
					if($resultado.message.text -match "^sql"){
						$sair=0;
                        send_telegram "Voce esta conectado"
                        ${instancia}=($resultado.message.text -split " ")[1]
                        Start-Sleep -Milliseconds 800
					#Detalhes sobre a conexão
					}elseif($resultado.message.text -match "^conexão"){
                        send_telegram "Você esta conectado na instancia ${instancia}" 
                    #Sair da conexão
					}elseif($resultado.message.text -match "^exit"){
						$sair=1
					#Executando conexão
					}elseif($sair -eq 0 ){
						command_sql -comando $resultado.message.text
						Start-Sleep -Milliseconds 1000
					#Teste conexão
					}elseif($resultado.message.text -match ""){
						send_telegram "Voce não esta conectado"
					}
				}
			}
		}
	}while($sair -eq 0 );
	
}


##Main programa
###Variables
$token="462696860:AAEY67IEAHdy2g3nHICzpoPFLbqS30E-b1M"
$idchat=-284232043
$userOracle="marcos"
$senhaOracle="teste"
$caminhoArquivo="C:\Projeto\oracle"
$proxyCaminho="proxy.texte:3128"

get_telegram ""



