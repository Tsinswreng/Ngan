-Sesn[
	-T[2026_0718_131122][
		先看skill。
		然後看CsNgaq這個項目。
		客戶端發版的時候、
		有以下流程:
		
		手上改代碼中的AppVer
		`E:\_code\CsNgaq\Ngaq.Core\Infra\AppVersion.cs`
		
		寫更新說明
		`E:\_code\CsNgaq\CHANGELOG.typ`
		
		安卓改版本號
		`E:\_code\CsNgaq\Ngaq.Frontend\proj\Ngaq.Android\Ngaq.Android.csproj
		<ApplicationDisplayVersion>1.2.17.26276</ApplicationDisplayVersion>
		`
		
		發佈安卓包
		`sh PublishAndroid.sh`
		
		然後手動把版本號重命名上apk上去
		
		發佈windows包
		`sh PublishWin.sh`
		
		然後手動打壓縮包、加版本號命名。
		
		在windows上升級的時候還要手動解壓、再把我的舊的文件夾的配置文件和sqlite數據庫弄到新的上面
		
		然後 這個項目拆成了很多個git倉庫。
		每次發版的時候是沒有git留存的、也不會在github release上產出。
		
		你覺得怎麼管理比較好
	][
		
	]
]
