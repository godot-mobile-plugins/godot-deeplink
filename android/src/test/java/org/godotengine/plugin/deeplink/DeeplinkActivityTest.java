//
// © 2024-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.deeplink;

import android.content.Intent;
import android.net.Uri;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for {@link DeeplinkActivity}.
 *
 * <p>{@link DeeplinkActivity#checkIntent(Intent)} is the only method that can be
 * exercised without an Android runtime, because it is {@code static} and
 * self-contained. The Activity lifecycle methods ({@code onCreate},
 * {@code onNewIntent}) depend on the Android framework and the Godot engine's
 * native runtime; they are covered by instrumented tests.
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("DeeplinkActivity")
class DeeplinkActivityTest {

	@Mock
	private Intent mockIntent;

	@Mock
	private Uri mockUri;

	// -- checkIntent – happy paths ----------------------------------------------

	@Nested
	@DisplayName("checkIntent() – Intent carries a URI")
	class WithValidUri {

		@Test
		@DisplayName("returns the URI extracted from the Intent")
		void returnsUri() {
			when(mockIntent.getData()).thenReturn(mockUri);

			Uri result = DeeplinkActivity.checkIntent(mockIntent);

			assertNotNull(result);
			assertEquals(mockUri, result);
		}

		@Test
		@DisplayName("invokes Intent.getData() exactly once")
		void invokesGetDataOnce() {
			when(mockIntent.getData()).thenReturn(mockUri);

			DeeplinkActivity.checkIntent(mockIntent);

			verify(mockIntent, times(1)).getData();
		}

		@Test
		@DisplayName("returned URI is the same object supplied by Intent.getData()")
		void returnedUriIsSameObject() {
			when(mockIntent.getData()).thenReturn(mockUri);

			Uri result = DeeplinkActivity.checkIntent(mockIntent);

			// Intentional identity check: no defensive copy should be made.
			//noinspection ConstantValue
			assertEquals(mockUri, result);
		}
	}

	// -- checkIntent – null URI -------------------------------------------------

	@Nested
	@DisplayName("checkIntent() – Intent has no URI data")
	class WithNullUri {

		@Test
		@DisplayName("returns null when Intent.getData() returns null")
		void returnsNull() {
			when(mockIntent.getData()).thenReturn(null);

			Uri result = DeeplinkActivity.checkIntent(mockIntent);

			assertNull(result);
		}

		@Test
		@DisplayName("still calls Intent.getData() to attempt extraction")
		void callsGetData() {
			when(mockIntent.getData()).thenReturn(null);

			DeeplinkActivity.checkIntent(mockIntent);

			verify(mockIntent, times(1)).getData();
		}
	}

	// -- checkIntent – null Intent ----------------------------------------------

	@Nested
	@DisplayName("checkIntent() – null Intent")
	class WithNullIntent {

		@Test
		@DisplayName("returns null without throwing")
		void returnsNullSafely() {
			Uri result = DeeplinkActivity.checkIntent(null);

			assertNull(result);
		}

		@Test
		@DisplayName("does not interact with any Intent mock")
		void doesNotInteractWithIntent() {
			DeeplinkActivity.checkIntent(null);

			// mockIntent must never have been touched; Mockito strict mode
			// would catch unexpected interactions automatically, but we
			// make the assertion explicit for documentation purposes.
			verify(mockIntent, times(0)).getData();
		}
	}

	// -- checkIntent – URI sourced from fixture ---------------------------------

	@Nested
	@DisplayName("checkIntent() – fixture-based URIs")
	class WithFixtureUri {

		@Test
		@DisplayName("returns the full fixture URI when Intent carries it")
		void fullFixtureUri_returned() {
			Uri fixtureUri = DeeplinkFixtures.fullUri();
			Intent intent = DeeplinkFixtures.intentWithUri(fixtureUri);

			Uri result = DeeplinkActivity.checkIntent(intent);

			assertEquals(fixtureUri, result);
		}

		@Test
		@DisplayName("returns the minimal fixture URI when Intent carries it")
		void minimalFixtureUri_returned() {
			Uri fixtureUri = DeeplinkFixtures.minimalUri();
			Intent intent = DeeplinkFixtures.intentWithUri(fixtureUri);

			Uri result = DeeplinkActivity.checkIntent(intent);

			assertEquals(fixtureUri, result);
		}

		@Test
		@DisplayName("returns null for an Intent created without a URI")
		void intentWithoutUri_returnsNull() {
			Intent intent = DeeplinkFixtures.intentWithoutUri();

			Uri result = DeeplinkActivity.checkIntent(intent);

			assertNull(result);
		}
	}
}
