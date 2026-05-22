//
// © 2024-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.deeplink;

import android.net.Uri;

import org.godotengine.godot.Dictionary;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Unit tests for {@link DeeplinkUrl}.
 *
 * <p>Each test creates (or re-uses) a mocked {@link Uri} so no Android runtime
 * is required. Tests are grouped by the URI component they exercise and cover
 * both the "value present" and "value absent" branches inside the constructor.
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("DeeplinkUrl")
class DeeplinkUrlTest {

	// -- Full URI ---------------------------------------------------------------

	@Nested
	@DisplayName("full URI with all components")
	class FullUri {

		@Test
		@DisplayName("scheme is stored")
		void scheme_isStored() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.fullUri()).getRawData();
			assertEquals(DeeplinkFixtures.SCHEME_HTTPS, data.get("scheme"));
		}

		@Test
		@DisplayName("user is stored")
		void user_isStored() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.fullUri()).getRawData();
			assertEquals(DeeplinkFixtures.USER_NAME, data.get("user"));
		}

		@Test
		@DisplayName("password is stored")
		void password_isStored() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.fullUri()).getRawData();
			assertEquals(DeeplinkFixtures.PASSWORD, data.get("password"));
		}

		@Test
		@DisplayName("host is stored")
		void host_isStored() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.fullUri()).getRawData();
			assertEquals(DeeplinkFixtures.HOST_EXAMPLE, data.get("host"));
		}

		@Test
		@DisplayName("port is stored")
		void port_isStored() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.fullUri()).getRawData();
			assertEquals(DeeplinkFixtures.PORT_VALID, data.get("port"));
		}

		@Test
		@DisplayName("path is stored")
		void path_isStored() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.fullUri()).getRawData();
			assertEquals(DeeplinkFixtures.PATH_PRODUCT, data.get("path"));
		}

		@Test
		@DisplayName("query string is stored")
		void query_isStored() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.fullUri()).getRawData();
			assertEquals(DeeplinkFixtures.QUERY_STRING, data.get("query"));
		}

		@Test
		@DisplayName("fragment is stored")
		void fragment_isStored() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.fullUri()).getRawData();
			assertEquals(DeeplinkFixtures.FRAGMENT, data.get("fragment"));
		}
	}

	// -- Minimal URI -----------------------------------------------------------

	@Nested
	@DisplayName("minimal URI (scheme + host only)")
	class MinimalUri {

		@Test
		@DisplayName("user key is absent when userInfo is null")
		void user_isAbsent() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.minimalUri()).getRawData();
			assertNull(data.get("user"));
		}

		@Test
		@DisplayName("password key is absent when userInfo is null")
		void password_isAbsent() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.minimalUri()).getRawData();
			assertNull(data.get("password"));
		}

		@Test
		@DisplayName("port key is absent when Uri.getPort() returns -1")
		void port_isAbsent() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.minimalUri()).getRawData();
			assertNull(data.get("port"));
		}

		@Test
		@DisplayName("path key is absent when path is null")
		void path_isAbsent() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.minimalUri()).getRawData();
			assertNull(data.get("path"));
		}

		@Test
		@DisplayName("path_extension key is absent when path is null")
		void pathExtension_isAbsent() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.minimalUri()).getRawData();
			assertNull(data.get("path_extension"));
		}

		@Test
		@DisplayName("path_components key is absent when path is null")
		void pathComponents_isAbsent() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.minimalUri()).getRawData();
			assertNull(data.get("path_components"));
		}

		@Test
		@DisplayName("query key is absent when query is null")
		void query_isAbsent() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.minimalUri()).getRawData();
			assertNull(data.get("query"));
		}

		@Test
		@DisplayName("fragment key is absent when fragment is null")
		void fragment_isAbsent() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.minimalUri()).getRawData();
			assertNull(data.get("fragment"));
		}
	}

	// -- Scheme edge cases ------------------------------------------------------

	@Nested
	@DisplayName("scheme edge cases")
	class SchemeEdgeCases {

		@Test
		@DisplayName("scheme is absent when Uri.getScheme() returns empty string")
		void emptyScheme_isAbsent() {
			Uri uri = mock(Uri.class);
			when(uri.getScheme()).thenReturn("");
			when(uri.getUserInfo()).thenReturn(null);
			when(uri.getHost()).thenReturn(DeeplinkFixtures.HOST_EXAMPLE);
			when(uri.getPort()).thenReturn(DeeplinkFixtures.PORT_ABSENT);
			when(uri.getPath()).thenReturn(null);
			when(uri.getQuery()).thenReturn(null);
			when(uri.getFragment()).thenReturn(null);

			Dictionary data = new DeeplinkUrl(uri).getRawData();
			assertNull(data.get("scheme"));
		}

		@Test
		@DisplayName("custom scheme is stored correctly")
		void customScheme_isStored() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.uriWithSingleExtension()).getRawData();
			assertEquals(DeeplinkFixtures.SCHEME_CUSTOM, data.get("scheme"));
		}
	}

	// -- Path extension ---------------------------------------------------------

	@Nested
	@DisplayName("path_extension extraction")
	class PathExtension {

		@Test
		@DisplayName("single extension is extracted from path")
		void singleExtension_isExtracted() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.uriWithSingleExtension()).getRawData();
			assertEquals("pdf", data.get("path_extension"));
		}

		@Test
		@DisplayName("only the last extension is stored for multi-dot paths")
		void multiDotPath_lastExtensionStored() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.uriWithMultipleExtensions()).getRawData();
			assertEquals("gz", data.get("path_extension"));
		}

		@Test
		@DisplayName("path_extension is absent when path has no dot")
		void noDot_extensionIsAbsent() {
			Uri uri = mock(Uri.class);
			when(uri.getScheme()).thenReturn(DeeplinkFixtures.SCHEME_HTTPS);
			when(uri.getUserInfo()).thenReturn(null);
			when(uri.getHost()).thenReturn(DeeplinkFixtures.HOST_EXAMPLE);
			when(uri.getPort()).thenReturn(DeeplinkFixtures.PORT_ABSENT);
			when(uri.getPath()).thenReturn(DeeplinkFixtures.PATH_PRODUCT);
			when(uri.getQuery()).thenReturn(null);
			when(uri.getFragment()).thenReturn(null);

			Dictionary data = new DeeplinkUrl(uri).getRawData();
			assertNull(data.get("path_extension"));
		}

		@Test
		@DisplayName("path_extension is absent when path ends with a bare dot")
		void trailingDot_extensionIsAbsent() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.uriWithTrailingDotPath()).getRawData();
			// PATH_TRAILING_DOT = "/files/document." — lastDot+1 == path.length()
			assertNull(data.get("path_extension"));
		}
	}

	// -- Path components --------------------------------------------------------

	@Nested
	@DisplayName("path_components extraction")
	class PathComponents {

		@Test
		@DisplayName("multi-segment path yields correct array of components")
		void multiSegment_correctComponents() {
			Uri uri = mock(Uri.class);
			when(uri.getScheme()).thenReturn(DeeplinkFixtures.SCHEME_HTTPS);
			when(uri.getUserInfo()).thenReturn(null);
			when(uri.getHost()).thenReturn(DeeplinkFixtures.HOST_EXAMPLE);
			when(uri.getPort()).thenReturn(DeeplinkFixtures.PORT_ABSENT);
			when(uri.getPath()).thenReturn("/products/42");
			when(uri.getQuery()).thenReturn(null);
			when(uri.getFragment()).thenReturn(null);

			String[] components = (String[]) new DeeplinkUrl(uri).getRawData().get("path_components");
			assertNotNull(components);
			assertArrayEquals(new String[]{"products", "42"}, components);
		}

		@Test
		@DisplayName("single-segment path yields a one-element array")
		void singleSegment_oneElement() {
			Uri uri = mock(Uri.class);
			when(uri.getScheme()).thenReturn(DeeplinkFixtures.SCHEME_HTTPS);
			when(uri.getUserInfo()).thenReturn(null);
			when(uri.getHost()).thenReturn(DeeplinkFixtures.HOST_EXAMPLE);
			when(uri.getPort()).thenReturn(DeeplinkFixtures.PORT_ABSENT);
			when(uri.getPath()).thenReturn("/page");
			when(uri.getQuery()).thenReturn(null);
			when(uri.getFragment()).thenReturn(null);

			String[] components = (String[]) new DeeplinkUrl(uri).getRawData().get("path_components");
			assertNotNull(components);
			assertArrayEquals(new String[]{"page"}, components);
		}

		@Test
		@DisplayName("path_components from uriWithSingleExtension matches expected segments")
		void extensionPath_componentsMatchExpected(@Mock Uri ignored) {
			// PATH_WITH_EXT = "/files/document.pdf"
			String[] components = (String[]) new DeeplinkUrl(
					DeeplinkFixtures.uriWithSingleExtension()).getRawData().get("path_components");
			assertNotNull(components);
			assertArrayEquals(new String[]{"files", "document.pdf"}, components);
		}
	}

	// -- User info --------------------------------------------------------------

	@Nested
	@DisplayName("user info parsing")
	class UserInfo {

		@Test
		@DisplayName("both user and password are stored when colon delimiter is present")
		void colonDelimited_bothStored() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.fullUri()).getRawData();
			assertEquals(DeeplinkFixtures.USER_NAME, data.get("user"));
			assertEquals(DeeplinkFixtures.PASSWORD, data.get("password"));
		}

		@Test
		@DisplayName("only user is stored when userInfo contains no colon")
		void noColon_onlyUserStored() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.uriWithUsernameOnly()).getRawData();
			assertEquals(DeeplinkFixtures.USER_NAME, data.get("user"));
			assertNull(data.get("password"));
		}

		@Test
		@DisplayName("password is absent when the password segment is empty")
		void emptyPasswordSegment_passwordAbsent() {
			Uri uri = mock(Uri.class);
			when(uri.getScheme()).thenReturn(DeeplinkFixtures.SCHEME_HTTPS);
			// "alice:" – colon present but empty password segment
			when(uri.getUserInfo()).thenReturn(DeeplinkFixtures.USER_NAME + ":");
			when(uri.getHost()).thenReturn(DeeplinkFixtures.HOST_EXAMPLE);
			when(uri.getPort()).thenReturn(DeeplinkFixtures.PORT_ABSENT);
			when(uri.getPath()).thenReturn(null);
			when(uri.getQuery()).thenReturn(null);
			when(uri.getFragment()).thenReturn(null);

			Dictionary data = new DeeplinkUrl(uri).getRawData();
			assertEquals(DeeplinkFixtures.USER_NAME, data.get("user"));
			assertNull(data.get("password"));
		}
	}

	// -- Port ------------------------------------------------------------------

	@Nested
	@DisplayName("port handling")
	class Port {

		@Test
		@DisplayName("port is stored when Uri.getPort() returns a non-negative value")
		void positivePort_isStored() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.fullUri()).getRawData();
			assertEquals(DeeplinkFixtures.PORT_VALID, data.get("port"));
		}

		@Test
		@DisplayName("port key is absent when Uri.getPort() returns -1")
		void negativePort_isAbsent() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.minimalUri()).getRawData();
			assertNull(data.get("port"));
		}

		@Test
		@DisplayName("port value 0 is treated as a valid port and stored")
		void zeroPort_isStored() {
			Uri uri = mock(Uri.class);
			when(uri.getScheme()).thenReturn(DeeplinkFixtures.SCHEME_HTTPS);
			when(uri.getUserInfo()).thenReturn(null);
			when(uri.getHost()).thenReturn(DeeplinkFixtures.HOST_EXAMPLE);
			when(uri.getPort()).thenReturn(0);
			when(uri.getPath()).thenReturn(null);
			when(uri.getQuery()).thenReturn(null);
			when(uri.getFragment()).thenReturn(null);

			Dictionary data = new DeeplinkUrl(uri).getRawData();
			assertEquals(0, data.get("port"));
		}
	}

	// -- getRawData -------------------------------------------------------------

	@Nested
	@DisplayName("getRawData()")
	class GetRawData {

		@Test
		@DisplayName("returns a non-null Dictionary for a full URI")
		void fullUri_returnsNonNullDictionary() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.fullUri()).getRawData();
			assertNotNull(data);
		}

		@Test
		@DisplayName("returns a non-null Dictionary for a minimal URI")
		void minimalUri_returnsNonNullDictionary() {
			Dictionary data = new DeeplinkUrl(DeeplinkFixtures.minimalUri()).getRawData();
			assertNotNull(data);
		}
	}
}
