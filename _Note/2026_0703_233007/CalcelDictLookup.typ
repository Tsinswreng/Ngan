詞典頁中
E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Ui\Views\Dictionary\ViewDictionary.cs

當我輸入單詞 點擊查詢按鈕、大模型還沒響應、過了一會我再次點擊查詢按鈕來取消、
UI上報錯 「未知錯誤」
然後日誌上面寫的是
````

fail: GlobalLogger[0]
      System.Threading.Tasks.TaskCanceledException: The operation was canceled.
       ---> System.Threading.Tasks.TaskCanceledException: The operation was canceled.
       ---> System.IO.IOException: Unable to read data from the transport connection: 由于线程退出或应用程序请求，已中止 I/O 操作。.
       ---> System.Net.Sockets.SocketException (995): 由于线程退出或应用程序请求，已中止 I/O 操作。
         --- End of inner exception stack trace ---
         at System.Net.Sockets.Socket.AwaitableSocketAsyncEventArgs.ThrowException(SocketError error, CancellationToken cancellationToken)
         at System.Net.Sockets.Socket.AwaitableSocketAsyncEventArgs.System.Threading.Tasks.Sources.IValueTaskSource<System.Int32>.GetResult(Int16 token)
         at System.Net.Http.HttpConnection.RawConnectionStream.ReadAsync(Memory`1 buffer, CancellationToken cancellationToken)
         at System.Runtime.CompilerServices.PoolingAsyncValueTaskMethodBuilder`1.StateMachineBox`1.System.Threading.Tasks.Sources.IValueTaskSource<TResult>.GetResult(Int16 token)
         at System.Net.Security.SslStream.EnsureFullTlsFrameAsync[TIOAdapter](CancellationToken cancellationToken, Int32 estimatedSize)
         at System.Runtime.CompilerServices.PoolingAsyncValueTaskMethodBuilder`1.StateMachineBox`1.System.Threading.Tasks.Sources.IValueTaskSource<TResult>.GetResult(Int16 token)
         at System.Net.Security.SslStream.ReadAsyncInternal[TIOAdapter](Memory`1 buffer, CancellationToken cancellationToken)
         at System.Runtime.CompilerServices.PoolingAsyncValueTaskMethodBuilder`1.StateMachineBox`1.System.Threading.Tasks.Sources.IValueTaskSource<TResult>.GetResult(Int16 token)
         at System.Net.Http.HttpConnection.InitialFillAsync(Boolean async)
         at System.Net.Http.HttpConnection.SendAsync(HttpRequestMessage request, Boolean async, CancellationToken cancellationToken)
         --- End of inner exception stack trace ---
         at System.Net.Http.HttpConnection.SendAsync(HttpRequestMessage request, Boolean async, CancellationToken cancellationToken)
         at System.Net.Http.HttpConnectionPool.SendWithVersionDetectionAndRetryAsync(HttpRequestMessage request, Boolean async, Boolean doRequestAuth, CancellationToken cancellationToken)
         at System.Net.Http.RedirectHandler.SendAsync(HttpRequestMessage request, Boolean async, CancellationToken cancellationToken)
         at System.Net.Http.SocketsHttpHandler.<SendAsync>g__CreateHandlerAndSendAsync|115_0(HttpRequestMessage request, CancellationToken cancellationToken)
         at System.Net.Http.HttpClient.<SendAsync>g__Core|83_0(HttpRequestMessage request, HttpCompletionOption completionOption, CancellationTokenSource cts, Boolean disposeCts, CancellationTokenSource pendingRequestsCts, CancellationToken originalCancellationToken)
         --- End of inner exception stack trace ---
         at System.Net.Http.HttpClient.HandleFailure(Exception e, Boolean telemetryStarted, HttpResponseMessage response, CancellationTokenSource cts, CancellationToken cancellationToken, CancellationTokenSource pendingRequestsCts)
         at System.Net.Http.HttpClient.<SendAsync>g__Core|83_0(HttpRequestMessage request, HttpCompletionOption completionOption, CancellationTokenSource cts, Boolean disposeCts, CancellationTokenSource pendingRequestsCts, CancellationToken originalCancellationToken)
         at Ngan.Dict.Backend.Domains.Dictionary.Svc.SvcDictionary.CallLlmApiStream(IReqLlmDictEvt evt, DtoLlmCallParam param, CancellationToken Ct) in E:\_code\CsNgan.Dict\Ngan.Dict.Backend\Domains\Dictionary\Svc\SvcDictionary.cs:line 414
         at Ngan.Dict.Backend.Domains.Dictionary.Svc.SvcDictionary.Lookup(IUserCtx User, IReqLlmDict Req, CancellationToken Ct) in E:\_code\CsNgan.Dict\Ngan.Dict.Backend\Domains\Dictionary\Svc\SvcDictionary.cs:line 199
         at Ngan.Dict.Ui.Views.Dictionary.VmDictionary.Lookup(CancellationToken Ct) in E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Ui\Views\Dictionary\VmDictionary.cs:line 250
````
預期效果是 不要在UI上彈「未知錯誤」


如果大模型已經開始響應了 但還沒響應完、這時我再點擊查詢按鈕來取消、
就沒有任何效果。
預期效果是 中斷此次查詢、UI上已經流式響應出的釋義就留着、UI上的單詞不再變化。

你看看這樣改有沒有問題。
