//
// © 2024-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.deeplink;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;

public class DeeplinkActivity extends Activity {
	private static final String CLASS_NAME = DeeplinkActivity.class.getSimpleName();
	private static final String LOG_TAG = "godot::" + CLASS_NAME;

	private static final String GODOT_APP_MAIN_ACTIVITY_CLASSPATH = "com.godot.game.GodotApp";
	private static Class<?> godotAppMainActivityClass = null;

	static {
		try {
			godotAppMainActivityClass = Class.forName(GODOT_APP_MAIN_ACTIVITY_CLASSPATH);
		} catch (ClassNotFoundException e) {
			Log.e(LOG_TAG, "could not find " + GODOT_APP_MAIN_ACTIVITY_CLASSPATH);
		}
	}

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		Log.d(LOG_TAG, "onCreate() " + CLASS_NAME);

		Intent intent = getIntent();
		Uri uri = checkIntent(intent);
		if (uri != null) {
			startGodot(intent, uri);
		}
	}

	@Override
	protected void onNewIntent(Intent intent) {
		super.onNewIntent(intent);

		Log.d(LOG_TAG, "onNewIntent() " + CLASS_NAME + " new intent: " + intent);
		Uri uri = checkIntent(intent);
		if (uri != null) {
			startGodot(intent, uri);
		}
	}

	private void startGodot(Intent intent, Uri uri) {
		if (DeeplinkPlugin.instance == null) {
			Intent godotIntent = new Intent(getApplicationContext(), godotAppMainActivityClass);
			godotIntent.setData(intent.getData());
			godotIntent.putExtras(intent);
			godotIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
			Log.d(LOG_TAG, "startGodot() " + CLASS_NAME + " with " + godotIntent);
			startActivity(godotIntent);
		} else {
			Log.i(LOG_TAG, "startGodot(): Godot is already running.");
			DeeplinkPlugin.instance.handleDeeplinkReceived(new DeeplinkUrl(uri).getRawData());
		}
		finish();
	}

	static Uri checkIntent(Intent intent) {
		Uri uri = null;

		if (intent != null) {
			uri = intent.getData();
			if (uri != null) {
				Log.d(LOG_TAG, "checkIntent() " + CLASS_NAME + " received app link data " + uri);
			}
			else {
				Log.d(LOG_TAG, "checkIntent() " + CLASS_NAME + " uri is null for intent " + intent);
			}
		}
		else {
			Log.d(LOG_TAG, "checkIntent() " + CLASS_NAME + " intent is null.");
		}

		return uri;
	}
}
