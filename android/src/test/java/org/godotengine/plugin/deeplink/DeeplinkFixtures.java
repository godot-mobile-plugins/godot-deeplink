//
// © 2024-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.deeplink;

import android.content.Intent;
import android.net.Uri;

import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mock;

/**
 * Shared test fixtures for the Deeplink plugin test suite.
 *
 * <p>Factory methods return freshly configured Mockito mocks so each test starts
 * from a clean, independent state. Constants are provided alongside the factories
 * so assertions can reference the same literal values that were injected into the
 * mock without duplicating magic strings.
 *
 * <h2>Design notes</h2>
 * <ul>
 *   <li>All stubs use {@code lenient()} so that focused single-field tests do not
 *       trigger {@code UnnecessaryStubbingException} when they consume only one
 *       of the many stubbed methods on a URI mock.</li>
 *   <li>{@link #intentWithUri(Uri)} pre-computes the string representation of the
 *       URI <em>before</em> entering any {@code when()} chain. Evaluating
 *       {@code uri.toString()} inside a {@code thenReturn()} argument while another
 *       {@code when()} is still open confuses Mockito's invocation recorder and
 *       raises {@code UnfinishedStubbingException}.</li>
 *   <li>{@link #intentWithoutUri()} deliberately omits a {@code getDataString()}
 *       stub because {@link DeeplinkActivity#checkIntent} never calls that method;
 *       stubbing it would trigger {@code UnnecessaryStubbingException} in strict
 *       mode tests.</li>
 * </ul>
 */
public final class DeeplinkFixtures {

	// -- URI component constants ------------------------------------------------

	public static final String SCHEME_HTTPS  = "https";
	public static final String SCHEME_CUSTOM = "myapp";

	public static final String HOST_EXAMPLE = "example.com";
	public static final String HOST_STORE   = "store.example.com";

	/** Multi-segment path with no file extension. */
	public static final String PATH_PRODUCT      = "/products/42";

	/** Path whose last segment carries a single file extension. */
	public static final String PATH_WITH_EXT     = "/files/document.pdf";

	/** Path with two dot-separated extensions; only the last should be stored. */
	public static final String PATH_MULTI_EXT    = "/files/archive.tar.gz";

	/** Path ending with a bare dot – no extension should be extracted. */
	public static final String PATH_TRAILING_DOT = "/files/document.";

	public static final String QUERY_STRING = "ref=home&promo=abc";
	public static final String FRAGMENT     = "section-1";
	public static final String USER_NAME    = "alice";
	public static final String PASSWORD     = "secret";

	/** Valid port that must appear in the parsed dictionary. */
	public static final int PORT_VALID  = 8080;

	/** Sentinel Android uses when no port is specified ({@link Uri#getPort()} == -1). */
	public static final int PORT_ABSENT = -1;

	/** Pre-built full URL string matching {@link #fullUri()}. */
	public static final String FULL_URL =
			SCHEME_HTTPS + "://" + USER_NAME + ":" + PASSWORD
					+ "@" + HOST_EXAMPLE + ":" + PORT_VALID
					+ PATH_PRODUCT + "?" + QUERY_STRING + "#" + FRAGMENT;

	// -- URI mock factories -----------------------------------------------------

	/**
	 * Returns a lenient mock {@link Uri} populated with every supported component:
	 * scheme, user info (user + password), host, port, path, query string,
	 * fragment, and {@code toString()}.
	 */
	public static Uri fullUri() {
		Uri uri = mock(Uri.class);
		lenient().when(uri.getScheme()).thenReturn(SCHEME_HTTPS);
		lenient().when(uri.getUserInfo()).thenReturn(USER_NAME + ":" + PASSWORD);
		lenient().when(uri.getHost()).thenReturn(HOST_EXAMPLE);
		lenient().when(uri.getPort()).thenReturn(PORT_VALID);
		lenient().when(uri.getPath()).thenReturn(PATH_PRODUCT);
		lenient().when(uri.getQuery()).thenReturn(QUERY_STRING);
		lenient().when(uri.getFragment()).thenReturn(FRAGMENT);
		lenient().when(uri.toString()).thenReturn(FULL_URL);
		return uri;
	}

	/**
	 * Returns a lenient mock {@link Uri} with only scheme and host – all optional
	 * components return {@code null} or the "port absent" sentinel {@code -1}.
	 */
	public static Uri minimalUri() {
		Uri uri = mock(Uri.class);
		lenient().when(uri.getScheme()).thenReturn(SCHEME_HTTPS);
		lenient().when(uri.getUserInfo()).thenReturn(null);
		lenient().when(uri.getHost()).thenReturn(HOST_EXAMPLE);
		lenient().when(uri.getPort()).thenReturn(PORT_ABSENT);
		lenient().when(uri.getPath()).thenReturn(null);
		lenient().when(uri.getQuery()).thenReturn(null);
		lenient().when(uri.getFragment()).thenReturn(null);
		lenient().when(uri.toString()).thenReturn(SCHEME_HTTPS + "://" + HOST_EXAMPLE);
		return uri;
	}

	/**
	 * Returns a lenient mock {@link Uri} whose path ends with a {@code .pdf}
	 * extension, used to verify that {@code path_extension} is correctly populated.
	 */
	public static Uri uriWithSingleExtension() {
		Uri uri = mock(Uri.class);
		lenient().when(uri.getScheme()).thenReturn(SCHEME_CUSTOM);
		lenient().when(uri.getUserInfo()).thenReturn(null);
		lenient().when(uri.getHost()).thenReturn(HOST_EXAMPLE);
		lenient().when(uri.getPort()).thenReturn(PORT_ABSENT);
		lenient().when(uri.getPath()).thenReturn(PATH_WITH_EXT);
		lenient().when(uri.getQuery()).thenReturn(null);
		lenient().when(uri.getFragment()).thenReturn(null);
		return uri;
	}

	/**
	 * Returns a lenient mock {@link Uri} whose path ends with {@code .tar.gz}.
	 * Only the last extension ({@code gz}) should be stored as
	 * {@code path_extension}.
	 */
	public static Uri uriWithMultipleExtensions() {
		Uri uri = mock(Uri.class);
		lenient().when(uri.getScheme()).thenReturn(SCHEME_CUSTOM);
		lenient().when(uri.getUserInfo()).thenReturn(null);
		lenient().when(uri.getHost()).thenReturn(HOST_EXAMPLE);
		lenient().when(uri.getPort()).thenReturn(PORT_ABSENT);
		lenient().when(uri.getPath()).thenReturn(PATH_MULTI_EXT);
		lenient().when(uri.getQuery()).thenReturn(null);
		lenient().when(uri.getFragment()).thenReturn(null);
		return uri;
	}

	/**
	 * Returns a lenient mock {@link Uri} whose path ends with a trailing dot.
	 * Because no character follows the dot, no extension should be extracted.
	 */
	public static Uri uriWithTrailingDotPath() {
		Uri uri = mock(Uri.class);
		lenient().when(uri.getScheme()).thenReturn(SCHEME_HTTPS);
		lenient().when(uri.getUserInfo()).thenReturn(null);
		lenient().when(uri.getHost()).thenReturn(HOST_EXAMPLE);
		lenient().when(uri.getPort()).thenReturn(PORT_ABSENT);
		lenient().when(uri.getPath()).thenReturn(PATH_TRAILING_DOT);
		lenient().when(uri.getQuery()).thenReturn(null);
		lenient().when(uri.getFragment()).thenReturn(null);
		return uri;
	}

	/**
	 * Returns a lenient mock {@link Uri} whose user-info string contains only a
	 * username with no colon delimiter, so no password should be extracted.
	 */
	public static Uri uriWithUsernameOnly() {
		Uri uri = mock(Uri.class);
		lenient().when(uri.getScheme()).thenReturn(SCHEME_HTTPS);
		lenient().when(uri.getUserInfo()).thenReturn(USER_NAME);
		lenient().when(uri.getHost()).thenReturn(HOST_EXAMPLE);
		lenient().when(uri.getPort()).thenReturn(PORT_ABSENT);
		lenient().when(uri.getPath()).thenReturn(null);
		lenient().when(uri.getQuery()).thenReturn(null);
		lenient().when(uri.getFragment()).thenReturn(null);
		return uri;
	}

	// -- Intent mock factories --------------------------------------------------

	/**
	 * Returns a lenient mock {@link Intent} whose {@code getData()} yields the
	 * given {@code uri} and {@code getDataString()} yields its string form.
	 *
	 * <p>{@code uriString} is evaluated <em>before</em> any {@code when()} chain
	 * opens. Calling {@code uri.toString()} inside a {@code thenReturn()} argument
	 * while another {@code when()} is still active causes Mockito's invocation
	 * recorder to raise {@code UnfinishedStubbingException}.
	 */
	public static Intent intentWithUri(Uri uri) {
		String uriString = uri.toString(); // must be pre-computed before when()
		Intent intent = mock(Intent.class);
		lenient().when(intent.getData()).thenReturn(uri);
		lenient().when(intent.getDataString()).thenReturn(uriString);
		return intent;
	}

	/**
	 * Returns a lenient mock {@link Intent} with no URI data; {@code getData()}
	 * returns {@code null}.
	 *
	 * <p>{@code getDataString()} is intentionally <em>not</em> stubbed:
	 * {@link DeeplinkActivity#checkIntent} never calls it, and an unused stub
	 * would raise {@code UnnecessaryStubbingException} in strict-mode tests.
	 */
	public static Intent intentWithoutUri() {
		Intent intent = mock(Intent.class);
		lenient().when(intent.getData()).thenReturn(null);
		return intent;
	}

	// -- Private constructor ----------------------------------------------------

	private DeeplinkFixtures() {
		// utility class – do not instantiate
	}
}
