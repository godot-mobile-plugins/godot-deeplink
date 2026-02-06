//
// © 2024-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.deeplink;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.verify.domain.DomainVerificationManager;
import android.content.pm.verify.domain.DomainVerificationUserState;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import android.util.Log;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import org.godotengine.godot.Dictionary;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.lang.reflect.Field;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class DeeplinkPlugin extends GodotPlugin {
	private static final String CLASS_NAME = DeeplinkPlugin.class.getSimpleName();
	private static final String LOG_TAG = "godot::" + CLASS_NAME;

	static DeeplinkPlugin instance;

	private static final SignalInfo DEEPLINK_RECEIVED_SIGNAL = new SignalInfo("deeplink_received", Dictionary.class);

	private Activity activity;
	private boolean is_initialized;

	public DeeplinkPlugin(Godot godot) {
		super(godot);
		is_initialized = false;
	}

	@UsedByGodot
	public int initialize() {
		int result = 0;

		if (!is_initialized) {
			is_initialized = true;
		}
		else {
			Log.w(LOG_TAG, "initialize(): plugin has already been initialized!");
		}

		return result;
	}

	@UsedByGodot
	public boolean is_domain_associated(String domain) {
		boolean result = false;

		if (activity != null) {
			Context context = activity.getApplicationContext();
			if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
				DomainVerificationManager manager = context.getSystemService(DomainVerificationManager.class);
				try {
					DomainVerificationUserState userState = manager.getDomainVerificationUserState(context.getPackageName());
					if (userState != null) {
						Map<String, Integer> hostToStateMap = userState.getHostToStateMap();
						if (hostToStateMap.containsKey(domain)) {
							Integer stateValue = hostToStateMap.get(domain);
							if (stateValue != null) {
								switch (stateValue) {
									case DomainVerificationUserState.DOMAIN_STATE_VERIFIED:
										result = true;
										Log.i(LOG_TAG, "is_domain_associated(): state of " + domain + " domain is verified for " + context.getPackageName());
										break;
									case DomainVerificationUserState.DOMAIN_STATE_SELECTED:
										result = true;
										Log.i(LOG_TAG, "is_domain_associated(): state of " + domain + " domain is selected for " + context.getPackageName());
										break;
									case DomainVerificationUserState.DOMAIN_STATE_NONE:
										Log.w(LOG_TAG, "is_domain_associated(): state of " + domain + " domain is 'none' for " + context.getPackageName());
										break;
									default:
										Log.e(LOG_TAG, "is_domain_associated(): invalid state of " + domain + " domain for " + context.getPackageName());
										break;
								}
							}
							else {
								Log.e(LOG_TAG, "is_domain_associated(): state for " + domain + "domain is null for " + context.getPackageName());
							}
						}
						else {
							Log.e(LOG_TAG, "is_domain_associated(): state for " + domain + "domain not found for " + context.getPackageName());
						}
					}
				} catch (PackageManager.NameNotFoundException e) {
					Log.e(LOG_TAG, "is_domain_associated(): package not found: " + context.getPackageName(), e);
				}
			}
			else {
				Log.e(LOG_TAG, "is_domain_associated(): android version " + android.os.Build.VERSION.SDK_INT + " is not supported. " +
						android.os.Build.VERSION_CODES.S + " is required.");
			}
		}
		else {
			Log.e(LOG_TAG, "is_domain_associated(): activity is null");
		}
		return result;
	}

	@UsedByGodot
	public void navigate_to_open_by_default_settings() {
		if (activity != null) {
			Context context = activity.getApplicationContext();
			if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
				// Check OneUI version to avoid OneUI bug with versions before 5.0.
				int oneUiVersion = -1;
				try {
					oneUiVersion = Build.VERSION.class.getDeclaredField("SEM_PLATFORM_INT").getInt(null);
				} catch (NoSuchFieldException e) {
					Log.d(LOG_TAG, "navigate_to_open_by_default_settings(): No SEM_PLATFORM_INT.");
				} catch (IllegalAccessException e) {
					Log.w(LOG_TAG, "navigate_to_open_by_default_settings(): Can't get One UI version.", e);
				}

				if (oneUiVersion < 0 || oneUiVersion >= 140000) {
					Log.i(LOG_TAG, "navigate_to_open_by_default_settings(): opening 'Open By Default' settings screen.");
					Intent intent = new Intent(Settings.ACTION_APP_OPEN_BY_DEFAULT_SETTINGS, Uri.parse("package:" + context.getPackageName()));
					intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
					context.startActivity(intent);
				}
				else {
					Log.i(LOG_TAG, "navigate_to_open_by_default_settings(): opening manage domain URLs settings screen.");
					Intent intent = new Intent();
					intent.setAction("android.settings.MANAGE_DOMAIN_URLS");
					intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
					context.startActivity(intent);
				}
			}
			else {
				Log.e(LOG_TAG, "navigate_to_open_by_default_settings(): android version " + android.os.Build.VERSION.SDK_INT + " is not supported. " +
						android.os.Build.VERSION_CODES.S + " is required.");
			}
		}
		else {
			Log.e(LOG_TAG, "navigate_to_open_by_default_settings(): activity is null");
		}
	}

	@UsedByGodot
	public String get_url() {
		String url = null;

		if (activity != null) {
			Intent currentIntent = activity.getIntent();

			if (currentIntent != null) {
				url = currentIntent.getDataString();
			}
		}
		else {
			Log.e(LOG_TAG, "get_url() activity is null");
		}

		Log.d(LOG_TAG, "get_url() returned " + (url == null ? "null" : url));
		return url;
	}

	@UsedByGodot
	public String get_scheme() {
		String scheme = null;

		if (activity != null) {
			Intent currentIntent = activity.getIntent();

			if (currentIntent != null) {
				Uri uri = currentIntent.getData();
				if (uri != null) {
					scheme = uri.getScheme();
				}
			}
		}
		else {
			Log.e(LOG_TAG, "get_scheme() activity is null");
		}

		Log.d(LOG_TAG, "get_scheme() returned " + (scheme == null ? "null" : scheme));
		return scheme;
	}

	@UsedByGodot
	public String get_host() {
		String host = null;

		if (activity != null) {
			Intent currentIntent = activity.getIntent();

			if (currentIntent != null) {
				Uri uri = currentIntent.getData();
				if (uri != null) {
					host = uri.getHost();
				}
			}
		}
		else {
			Log.e(LOG_TAG, "get_host() activity is null");
		}

		Log.d(LOG_TAG, "get_host() returned " + (host == null ? "null" : host));
		return host;
	}

	@UsedByGodot
	public String get_path() {
		String path = null;

		if (activity != null) {
			Intent currentIntent = activity.getIntent();

			if (currentIntent != null) {
				Uri uri = currentIntent.getData();
				if (uri != null) {
					path = uri.getPath();
				}
			}
		}
		else {
			Log.e(LOG_TAG, "get_path() activity is null");
		}

		Log.d(LOG_TAG, "get_path() returned " + (path == null ? "null" : path));
		return path;
	}

	@UsedByGodot
	public void clear_data() {
		if (activity != null) {
			Intent currentIntent = activity.getIntent();

			currentIntent.setData(null);

			Log.d(LOG_TAG, "clear_data() " + (currentIntent.getData() == null ? "successfully" : "unsuccessfully") + " cleared");
		}
		else {
			Log.e(LOG_TAG, "clear_data() activity is null");
		}
	}

	@NonNull
	@Override
	public String getPluginName() {
		return CLASS_NAME;
	}

	@NonNull
	@Override
	public Set<SignalInfo> getPluginSignals() {
		return new HashSet<>(List.of(DEEPLINK_RECEIVED_SIGNAL));
	}

	@Nullable
	@Override
	public View onMainCreate(Activity activity) {
		View view = super.onMainCreate(activity);

		Log.d(LOG_TAG, "onMainCreate() " + CLASS_NAME + " created.");

		this.activity = activity;
		instance = this;

		return view;
	}

	@Override
	public void onGodotSetupCompleted() {
		super.onGodotSetupCompleted();

		Intent intent = this.activity.getIntent();
		Uri uri = DeeplinkActivity.checkIntent(intent);
		if (uri != null) {
			handleDeeplinkReceived(new DeeplinkUrl(uri).getRawData());
		}
	}

	void handleDeeplinkReceived(Dictionary deeplinkData) {
		Log.d(LOG_TAG, "handleDeeplinkReceived() " + CLASS_NAME + " received " + deeplinkData.toString());
		GodotPlugin.emitSignal(getGodot(), getPluginName(), DEEPLINK_RECEIVED_SIGNAL, deeplinkData);
	}
}
