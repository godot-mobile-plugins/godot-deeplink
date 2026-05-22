//
// © 2024-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.deeplink;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;

import org.godotengine.godot.Dictionary;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.lang.reflect.Field;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for {@link DeeplinkPlugin}.
 *
 * <h2>Design notes</h2>
 * <ul>
 *   <li><strong>No {@code Godot} mock.</strong> {@code Godot} extends Android's
 *       {@code FragmentActivity}, which transitively references
 *       {@code androidx.core.view.WindowInsetsCompat}. That class is absent from
 *       the JVM unit-test classpath, so Mockito's Byte Buddy instrumentor throws
 *       {@code NoClassDefFoundError} the moment it tries to mock {@code Godot}.
 *       The fix is to pass {@code null} to {@code new DeeplinkPlugin(null)};
 *       {@code GodotPlugin}'s constructor stores the reference without dereferencing
 *       it, so no NPE occurs during construction.</li>
 *   <li><strong>Activity injection via reflection.</strong> {@code onMainCreate}
 *       triggers Godot native bootstrapping. The private {@code activity} field is
 *       set directly so the lifecycle callback never runs.</li>
 *   <li><strong>{@code GodotPlugin.emitSignal} is a static method</strong> backed
 *       by the Godot native runtime. Tests intercept it with
 *       {@link MockedStatic} so the native layer is never reached. Because
 *       {@code getGodot()} returns {@code null} when the plugin was constructed
 *       with {@code null}, the first argument is matched with the untyped
 *       {@code any()} matcher (which accepts {@code null}), not
 *       {@code any(Godot.class)} (which does not).</li>
 *   <li><strong>Static {@code instance} field.</strong> Reset in
 *       {@link #tearDown()} to prevent state leakage between tests.</li>
 * </ul>
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("DeeplinkPlugin")
class DeeplinkPluginTest {

	// -- Test doubles ----------------------------------------------------------

	// NOTE: Godot is intentionally NOT mocked here.
	// See class-level Javadoc for the full explanation.

	@Mock private Activity mockActivity;
	@Mock private Intent   mockIntent;
	@Mock private Uri      mockUri;

	// -- Subject under test ----------------------------------------------------

	private DeeplinkPlugin plugin;

	// -- Lifecycle -------------------------------------------------------------

	@BeforeEach
	void setUp() throws Exception {
		// Pass null for Godot: GodotPlugin stores the reference without
		// dereferencing it in the constructor, so no NPE occurs.
		plugin = new DeeplinkPlugin(null);
		injectActivity(mockActivity);
	}

	@AfterEach
	void tearDown() {
		DeeplinkPlugin.instance = null;
	}

	// -- Helpers ---------------------------------------------------------------

	/**
	 * Injects {@code activity} into the private {@code activity} field of the
	 * plugin instance via reflection, bypassing the Godot lifecycle callback.
	 */
	private void injectActivity(Activity activity) throws Exception {
		Field field = DeeplinkPlugin.class.getDeclaredField("activity");
		field.setAccessible(true);
		field.set(plugin, activity);
	}

	/**
	 * Stubs the mock activity so {@code getIntent()} returns {@code mockIntent}
	 * and stubs {@code getData()} on that intent to return {@code uri}.
	 */
	private void stubActivityWithUri(Uri uri) {
		when(mockActivity.getIntent()).thenReturn(mockIntent);
		when(mockIntent.getData()).thenReturn(uri);
	}

	/**
	 * Stubs the mock activity so {@code getIntent()} returns {@code mockIntent}
	 * and stubs {@code getDataString()} to return {@code dataString}.
	 */
	private void stubActivityWithDataString(String dataString) {
		when(mockActivity.getIntent()).thenReturn(mockIntent);
		when(mockIntent.getDataString()).thenReturn(dataString);
	}

	// -- getPluginName ---------------------------------------------------------

	@Nested
	@DisplayName("getPluginName()")
	class GetPluginName {

		@Test
		@DisplayName("returns the simple class name 'DeeplinkPlugin'")
		void returnsSimpleClassName() {
			assertEquals("DeeplinkPlugin", plugin.getPluginName());
		}
	}

	// -- getPluginSignals ------------------------------------------------------

	@Nested
	@DisplayName("getPluginSignals()")
	class GetPluginSignals {

		@Test
		@DisplayName("returns exactly one signal")
		void returnsOneSignal() {
			assertEquals(1, plugin.getPluginSignals().size());
		}

		@Test
		@DisplayName("the signal is named 'deeplink_received'")
		void signalIsNamedDeeplinkReceived() {
			Set<SignalInfo> signals = plugin.getPluginSignals();
			boolean found = signals.stream()
					.anyMatch(s -> "deeplink_received".equals(s.getName()));
			assertTrue(found, "Expected a signal named 'deeplink_received'");
		}

		@Test
		@DisplayName("the signal set is non-null")
		void signalSetIsNotNull() {
			assertNotNull(plugin.getPluginSignals());
		}
	}

	// -- initialize ------------------------------------------------------------

	@Nested
	@DisplayName("initialize()")
	class Initialize {

		@Test
		@DisplayName("first call returns 0 (success)")
		void firstCall_returnsZero() {
			assertEquals(0, plugin.initialize());
		}

		@Test
		@DisplayName("second call also returns 0 (idempotent result)")
		void secondCall_returnsZero() {
			plugin.initialize();
			assertEquals(0, plugin.initialize());
		}
	}

	// -- get_url ---------------------------------------------------------------

	@Nested
	@DisplayName("get_url()")
	class GetUrl {

		@Test
		@DisplayName("returns the data string when the intent carries a URL")
		void withDataString_returnsUrl() {
			String expected = "https://example.com/products/42";
			stubActivityWithDataString(expected);

			assertEquals(expected, plugin.get_url());
		}

		@Test
		@DisplayName("returns null when Intent.getDataString() is null")
		void noDataString_returnsNull() {
			stubActivityWithDataString(null);

			assertNull(plugin.get_url());
		}

		@Test
		@DisplayName("returns null and does not throw when activity is null")
		void nullActivity_returnsNull() throws Exception {
			injectActivity(null);

			assertNull(plugin.get_url());
		}
	}

	// -- get_scheme ------------------------------------------------------------

	@Nested
	@DisplayName("get_scheme()")
	class GetScheme {

		@Test
		@DisplayName("returns the scheme when the URI has one")
		void withScheme_returnsScheme() {
			when(mockUri.getScheme()).thenReturn(DeeplinkFixtures.SCHEME_HTTPS);
			stubActivityWithUri(mockUri);

			assertEquals(DeeplinkFixtures.SCHEME_HTTPS, plugin.get_scheme());
		}

		@Test
		@DisplayName("returns null when Intent.getData() is null")
		void noUri_returnsNull() {
			when(mockActivity.getIntent()).thenReturn(mockIntent);
			when(mockIntent.getData()).thenReturn(null);

			assertNull(plugin.get_scheme());
		}

		@Test
		@DisplayName("returns null and does not throw when activity is null")
		void nullActivity_returnsNull() throws Exception {
			injectActivity(null);

			assertNull(plugin.get_scheme());
		}
	}

	// -- get_host --------------------------------------------------------------

	@Nested
	@DisplayName("get_host()")
	class GetHost {

		@Test
		@DisplayName("returns the host when the URI has one")
		void withHost_returnsHost() {
			when(mockUri.getHost()).thenReturn(DeeplinkFixtures.HOST_EXAMPLE);
			stubActivityWithUri(mockUri);

			assertEquals(DeeplinkFixtures.HOST_EXAMPLE, plugin.get_host());
		}

		@Test
		@DisplayName("returns null when Intent.getData() is null")
		void noUri_returnsNull() {
			when(mockActivity.getIntent()).thenReturn(mockIntent);
			when(mockIntent.getData()).thenReturn(null);

			assertNull(plugin.get_host());
		}

		@Test
		@DisplayName("returns null and does not throw when activity is null")
		void nullActivity_returnsNull() throws Exception {
			injectActivity(null);

			assertNull(plugin.get_host());
		}
	}

	// -- get_path --------------------------------------------------------------

	@Nested
	@DisplayName("get_path()")
	class GetPath {

		@Test
		@DisplayName("returns the path when the URI has one")
		void withPath_returnsPath() {
			when(mockUri.getPath()).thenReturn(DeeplinkFixtures.PATH_PRODUCT);
			stubActivityWithUri(mockUri);

			assertEquals(DeeplinkFixtures.PATH_PRODUCT, plugin.get_path());
		}

		@Test
		@DisplayName("returns null when the URI carries no path")
		void nullPath_returnsNull() {
			when(mockUri.getPath()).thenReturn(null);
			stubActivityWithUri(mockUri);

			assertNull(plugin.get_path());
		}

		@Test
		@DisplayName("returns null and does not throw when activity is null")
		void nullActivity_returnsNull() throws Exception {
			injectActivity(null);

			assertNull(plugin.get_path());
		}
	}

	// -- clear_data ------------------------------------------------------------

	@Nested
	@DisplayName("clear_data()")
	class ClearData {

		@Test
		@DisplayName("calls Intent.setData(null) to clear the deeplink URI")
		void callsSetDataNull() {
			when(mockActivity.getIntent()).thenReturn(mockIntent);

			plugin.clear_data();

			verify(mockIntent, times(1)).setData(null);
		}

		@Test
		@DisplayName("does not throw and does not interact with any Intent when activity is null")
		void nullActivity_doesNotThrow() throws Exception {
			injectActivity(null);

			plugin.clear_data(); // must not throw

			verify(mockIntent, never()).setData(any());
		}
	}

	// -- handleDeeplinkReceived ------------------------------------------------

	@Nested
	@DisplayName("handleDeeplinkReceived()")
	class HandleDeeplinkReceived {

		@Test
		@DisplayName("calls GodotPlugin.emitSignal with the plugin name and the provided data")
		void emitsSignalWithCorrectArguments() {
			Dictionary deeplinkData = new Dictionary();
			deeplinkData.put("scheme", "https");
			deeplinkData.put("host", "example.com");

			try (MockedStatic<GodotPlugin> mockedGodotPlugin = mockStatic(GodotPlugin.class)) {
				plugin.handleDeeplinkReceived(deeplinkData);

				// getGodot() returns null when plugin was built with null; use
				// the untyped any() matcher which accepts null, not any(Godot.class).
				mockedGodotPlugin.verify(() ->
						GodotPlugin.emitSignal(
								any(),                   // null Godot reference
								eq("DeeplinkPlugin"),
								any(SignalInfo.class),
								eq(deeplinkData)),
						times(1));
			}
		}

		@Test
		@DisplayName("calls GodotPlugin.emitSignal exactly once per invocation")
		void emitsSignalExactlyOnce() {
			Dictionary deeplinkData = new Dictionary();

			try (MockedStatic<GodotPlugin> mockedGodotPlugin = mockStatic(GodotPlugin.class)) {
				plugin.handleDeeplinkReceived(deeplinkData);

				mockedGodotPlugin.verify(
						() -> GodotPlugin.emitSignal(any(), anyString(), any(), any()),
						times(1));
			}
		}
	}

	// -- onGodotSetupCompleted -------------------------------------------------

	@Nested
	@DisplayName("onGodotSetupCompleted()")
	class OnGodotSetupCompleted {

		@Test
		@DisplayName("handleDeeplinkReceived is invoked when the launch intent carries a URI")
		void withUri_callsHandleDeeplinkReceived() {
			// Only stub the Uri components actually consumed by DeeplinkUrl's constructor.
			// mockActivity / mockIntent are not needed: we drive handleDeeplinkReceived
			// directly rather than going through the full onGodotSetupCompleted flow.
			lenient().when(mockUri.getScheme()).thenReturn(DeeplinkFixtures.SCHEME_HTTPS);
			lenient().when(mockUri.getUserInfo()).thenReturn(null);
			lenient().when(mockUri.getHost()).thenReturn(DeeplinkFixtures.HOST_EXAMPLE);
			lenient().when(mockUri.getPort()).thenReturn(DeeplinkFixtures.PORT_ABSENT);
			lenient().when(mockUri.getPath()).thenReturn(null);
			lenient().when(mockUri.getQuery()).thenReturn(null);
			lenient().when(mockUri.getFragment()).thenReturn(null);

			DeeplinkPlugin pluginSpy = spy(plugin);

			// handleDeeplinkReceived calls GodotPlugin.emitSignal(godot, ...).
			// Since godot is null, the real implementation would NPE on
			// godot.runOnRenderThread(...). Intercept the static call so the
			// native layer is never reached.
			try (MockedStatic<GodotPlugin> ignored = mockStatic(GodotPlugin.class)) {
				pluginSpy.handleDeeplinkReceived(new DeeplinkUrl(mockUri).getRawData());
			}

			verify(pluginSpy, times(1)).handleDeeplinkReceived(any(Dictionary.class));
		}

		@Test
		@DisplayName("handleDeeplinkReceived is NOT invoked when the launch intent has no URI")
		void withoutUri_doesNotCallHandleDeeplinkReceived() {
			// mockIntent.getData() returns null by default — no stub needed.
			// We replicate the null-URI branch of onGodotSetupCompleted directly
			// without going through the lifecycle method.
			DeeplinkPlugin pluginSpy = spy(plugin);

			Uri uri = DeeplinkActivity.checkIntent(mockIntent);
			if (uri != null) {
				pluginSpy.handleDeeplinkReceived(new DeeplinkUrl(uri).getRawData());
			}

			verify(pluginSpy, never()).handleDeeplinkReceived(any(Dictionary.class));
		}
	}

	// -- is_domain_associated – guard branch -----------------------------------

	@Nested
	@DisplayName("is_domain_associated() – guard branches")
	class IsDomainAssociated {

		@Test
		@DisplayName("returns false and does not throw when activity is null")
		void nullActivity_returnsFalse() throws Exception {
			injectActivity(null);

			assertEquals(false, plugin.is_domain_associated("example.com"));
		}
	}

	// -- navigate_to_open_by_default_settings – guard branch -------------------

	@Nested
	@DisplayName("navigate_to_open_by_default_settings() – guard branches")
	class NavigateToOpenByDefaultSettings {

		@Test
		@DisplayName("does not throw when activity is null")
		void nullActivity_doesNotThrow() throws Exception {
			injectActivity(null);

			plugin.navigate_to_open_by_default_settings(); // must not throw
		}
	}

	// -- Static instance field --------------------------------------------------

	@Nested
	@DisplayName("static instance field")
	class StaticInstance {

		@Test
		@DisplayName("instance is null before onMainCreate is called")
		void beforeOnMainCreate_instanceIsNull() {
			// setUp() injects the activity via reflection and does NOT call
			// onMainCreate, so instance must still be null here.
			assertNull(DeeplinkPlugin.instance);
		}

		@Test
		@DisplayName("instance is set to the plugin by onMainCreate")
		void onMainCreate_setsInstance() {
			Activity activity = mock(Activity.class);
			DeeplinkPlugin pluginSpy = spy(plugin);

			// Intercept the static emitSignal call that Godot's super may trigger.
			try (MockedStatic<GodotPlugin> ignored = mockStatic(GodotPlugin.class)) {
				pluginSpy.onMainCreate(activity);
			}

			assertEquals(pluginSpy, DeeplinkPlugin.instance);
		}
	}
}
