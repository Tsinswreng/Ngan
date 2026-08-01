=
[2025-07-13T20:55:45.137+08:00_W28-7]
我做了一個源生成器工具叫CsDictMapper、用來做Dict和C\#對象的互轉。

我做了一個簡易ORM、叫CsSqlHelper。它使用了CsDictMapper、封裝了Ado.net。有如下功能: 實體類和數據庫表名的映射, 實體類字段及字段類型映射, 數據庫schema版本記錄, 根據實體的代碼配置生成建表sql語句, 簡易的實體增查改刪的倉儲類。設計了統一的適配層接口, 適配不同的數據庫 如sqlite, pg; 用接口方法抹除sql中有平臺差異的部分(如字段引號, 預編譯參數); 支持AOT兼容
項目結構長這樣
```
Directory.Build.props
Tsinswreng.CsSqlHelper/
	AdoTxn.cs
	bin/
	ColBuilder.cs
	Column.cs
	DbFactory.cs
	DbFnCtx.cs
	ExtnTblMgr.cs
	IColumn.cs
	Id_Dict.cs
	IDbFnCtx.cs
	IDbFnCtxMkr.cs
	IDbQry.cs
	IGetTxnAsy.cs
	IMigration.cs
	IRepo.cs
	ISoftDeleteCol.cs
	ISqlCmd.cs
	ISqlCmdMkr.cs
	ISqlMkr.cs
	ITable.cs
	ITableMgr.cs
	ITxn.cs
	ITxnAsyFnRunner.cs
	ITxnWrapper.cs
	ITypeNameMapper.cs
	obj/
	Page.cs
	Repo.cs
	SchemaHistory.cs
	ServiceSchemaHistory.cs
	SoftDeleteCol.cs
	SqlExpr.cs
	SqlTxnRunner.cs
	Table.cs
	Tsinswreng.CsSqlHelper.csproj
	TxnAsyFnRunner.cs
	TypeEnums.cs
	Version.cs
Tsinswreng.CsSqlHelper.EFCore/
Tsinswreng.CsSqlHelper.PostgreSql/
Tsinswreng.CsSqlHelper.Sqlite/
	SqliteCmd.cs
	SqliteSqlMkr.cs
	SqliteTblMgr.cs
	SqliteTypeMapper.cs
	SqlliteCmdMkr.cs
Tsinswreng.CsSqlHelper.Test/
TypeAlias.cs
```

用法:

```cs
```



我做了一個用于程序 用于背單詞 叫CsNgan.Dict
主要是C-S架構。客戶端是c\# avalonia寫的。目前支持windows, linux, Android平臺。支持AOT編譯。其中使用了我自己做的CsSqlHelper。
該程序不提供
