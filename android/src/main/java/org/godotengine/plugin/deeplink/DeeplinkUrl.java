//
// © 2024-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.deeplink;

import android.net.Uri;

import java.util.Arrays;

import org.godotengine.godot.Dictionary;

public class DeeplinkUrl {

	private static String SCHEME_PROPERTY = "scheme";
	private static String USER_PROPERTY = "user";
	private static String PASSWORD_PROPERTY = "password";
	private static String HOST_PROPERTY = "host";
	private static String PORT_PROPERTY = "port";
	private static String PATH_PROPERTY = "path";
	private static String PATH_EXTENSION_PROPERTY = "path_extension";
	private static String PATH_COMPONENTS_PROPERTY = "path_components";
	private static String QUERY_PROPERTY = "query";
	private static String FRAGMENT_PROPERTY = "fragment";

	private Dictionary _data;

	DeeplinkUrl(Uri uri) {
		this._data = new Dictionary();

		// Scheme
		String scheme = uri.getScheme();
		if (scheme != null && !scheme.isEmpty()) {
			_data.put(SCHEME_PROPERTY, scheme);
		}

		// User / Password
		String userInfo = uri.getUserInfo();
		if (userInfo != null && !userInfo.isEmpty()) {
			String[] parts = userInfo.split(":", 2);

			if (!parts[0].isEmpty()) {
				_data.put(USER_PROPERTY, parts[0]);
			}

			if (parts.length > 1 && !parts[1].isEmpty()) {
				_data.put(PASSWORD_PROPERTY, parts[1]);
			}
		}

		// Host
		String host = uri.getHost();
		if (host != null && !host.isEmpty()) {
			_data.put(HOST_PROPERTY, host);
		}

		// Port
		int port = uri.getPort();
		if (port >= 0) {
			_data.put(PORT_PROPERTY, port);
		}

		// Path
		String path = uri.getPath();
		if (path != null && !path.isEmpty()) {
			_data.put(PATH_PROPERTY, path);

			// Path extension
			int lastDot = path.lastIndexOf('.');
			int lastSlash = path.lastIndexOf('/');
			if (lastDot > lastSlash && lastDot + 1 < path.length()) {
				_data.put(PATH_EXTENSION_PROPERTY, path.substring(lastDot + 1));
			}

			// Path components as Java String[]
			String[] pathComponents = Arrays.stream(path.split("/"))
					.filter(c -> !c.isEmpty())
					.toArray(String[]::new);
			if (pathComponents.length > 0) {
				_data.put(PATH_COMPONENTS_PROPERTY, pathComponents);
			}
		}

		// Query
		String query = uri.getQuery();
		if (query != null && !query.isEmpty()) {
			_data.put(QUERY_PROPERTY, query);
		}

		// Fragment
		String fragment = uri.getFragment();
		if (fragment != null && !fragment.isEmpty()) {
			_data.put(FRAGMENT_PROPERTY, fragment);
		}
	}

	Dictionary getRawData() {
		return _data;
	}
}
