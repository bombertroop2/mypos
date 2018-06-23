package one_s.mobile.com.one_s


import android.os.Bundle
import android.support.v7.app.AppCompatActivity
import me.dm7.barcodescanner.zbar.ZBarScannerView
import android.util.Log
import me.dm7.barcodescanner.zbar.Result
import android.widget.Toast


class MainActivity : AppCompatActivity(), ZBarScannerView.ResultHandler {
    private lateinit var mScannerView: ZBarScannerView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        mScannerView = ZBarScannerView(this)
        setContentView(mScannerView)

    }

    override fun onResume() {
        super.onResume()
        mScannerView.startCamera()
    }

    override fun onPause() {
        super.onPause()
        mScannerView.stopCamera()
    }

    override fun handleResult(result: Result?) {
        Toast.makeText(this, result?.contents, Toast.LENGTH_SHORT).show()

        //Camera will stop after scanning result, so we need to resume the
        //preview in order scan more codes
        mScannerView.resumeCameraPreview(this)
    }
}