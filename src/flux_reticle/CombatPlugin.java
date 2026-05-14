package flux_reticle;

import com.fs.starfarer.api.GameState;
import com.fs.starfarer.api.Global;
import com.fs.starfarer.api.campaign.CampaignUIAPI;
import com.fs.starfarer.api.combat.*;
import com.fs.starfarer.api.graphics.SpriteAPI;
import com.fs.starfarer.api.input.InputEventAPI;
import com.fs.starfarer.api.util.Misc;
import lunalib.lunaSettings.LunaSettings;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.lwjgl.BufferUtils;
import org.lwjgl.input.Cursor;
import org.lwjgl.input.Keyboard;
import org.lwjgl.input.Mouse;
import org.lwjgl.util.vector.Vector2f;

import java.awt.*;
import java.io.IOException;
import java.util.List;
import java.util.MissingResourceException;

import static org.lwjgl.opengl.GL11.*;
import static org.lwjgl.opengl.GL11.glPopAttrib;

public class CombatPlugin implements EveryFrameCombatPlugin {
    public final static String PREFIX = "shat_fr_";
    public static final String ID = "shattersphere_flux_reticle_fork",
            SETTINGS_PATH = "FLUX_RETICLE_OPTIONS.ini",
            COMMON_DATA_PATH = "shat_fr/auto_turn_choices.json";

    static final String LUNALIB_ID = "lunalib";
    static JSONObject settingsCfg = null;
    static <T> T get(String id, Class<T> type) throws Exception {
        if(Global.getSettings().getModManager().isModEnabled(LUNALIB_ID)) {
            id = PREFIX + id;

            if(type == Integer.class) return type.cast(LunaSettings.getInt(ID, id));
            if(type == Float.class) return type.cast(LunaSettings.getFloat(ID, id));
            if(type == Boolean.class) return type.cast(LunaSettings.getBoolean(ID, id));
            if(type == Double.class) return type.cast(LunaSettings.getDouble(ID, id));
            if(type == String.class) return type.cast(LunaSettings.getString(ID, id));
            if(type == Color.class) {
                int red = getColorComponentFromLuna(id + "Red");
                int green = getColorComponentFromLuna(id + "Green");
                int blue = getColorComponentFromLuna(id + "Blue");
                int alpha = getColorComponentFromLuna(id + "Alpha");

                return (T)new Color(red, green, blue, alpha);
            }
        } else {
            if(settingsCfg == null) settingsCfg = Global.getSettings().getMergedJSONForMod(SETTINGS_PATH, ID);

            if(type == Integer.class) return type.cast(settingsCfg.getInt(id));
            if(type == Float.class) return type.cast((float) settingsCfg.getDouble(id));
            if(type == Boolean.class) return type.cast(settingsCfg.getBoolean(id));
            if(type == Double.class) return type.cast(settingsCfg.getDouble(id));
            if(type == String.class) return type.cast(settingsCfg.getString(id));
            if(type == Color.class) return type.cast(getColor(settingsCfg.getJSONArray(id)));
        }

        throw new MissingResourceException("No setting found with id: " + id, type.getName(), id);
    }
    static int getInt(String id) throws Exception { return get(id, Integer.class); }
    static double getDouble(String id) throws Exception { return get(id, Double.class); }
    static float getFloat(String id) throws Exception { return get(id, Float.class); }
    static boolean getBoolean(String id) throws Exception { return get(id, Boolean.class); }
    static String getString(String id) throws Exception { return get(id, String.class); }
    static Color getColor(String id) throws Exception { return get(id, Color.class); }
    static int getColorComponentFromLuna(String id) {
        return Math.max(0, Math.min(255, (int)LunaSettings.getInt(ID, id)));
    }
    boolean readSettings() throws Exception {
        showReticle = getBoolean("showReticle");
        showReticleWhenInterfaceIsHidden = getBoolean("showReticleWhenInterfaceIsHidden");
        glowOpacity = getInt("glowOpacity");
        spriteSet = getString("spriteSet");
        loadSpritesForSet(spriteSet);

        scale = (float) getDouble("sizeMult");
        reticleTopScale = (float) Math.max(0.1, getDouble("reticleTopScaleMult"));
        barWidth = (float) Math.max(0.5, getDouble("fluxBarWidth"));
        fluxBarBorderWidth = (float) Math.max(0, getDouble("fluxBarBorderWidth"));
        reticleTopOffset = (float) getDouble("reticleTopOffset");
        reticleTopLateralOffset = (float) getDouble("reticleTopLateralOffset");
        reticleBodyLateralOffset = (float) getDouble("reticleBodyLateralOffset");
        minLength = (float) Math.max(1, getDouble("minReticleLength"));
        maxLength = (float) Math.max(minLength, getDouble("maxReticleLength"));
        minDistance = (float) Math.max(0, getDouble("minReticleDistance"));
        maxDistance = (float) Math.max(minDistance + 0.001, getDouble("maxReticleDistance"));
        keepBarVisibleAtMinimumDistance = getBoolean("keepBarVisibleAtMinimumDistance");
        flashStartThreshold = (float) Math.max(0, Math.min(1, getDouble("flashStartThreshold")));
        flashMaxThreshold = (float) Math.max(flashStartThreshold + 0.001, Math.min(1, getDouble("flashMaxThreshold")));
        flashStartFrequency = (float) Math.max(0, getDouble("flashStartFrequency"));
        flashMaxFrequency = (float) Math.max(0, getDouble("flashMaxFrequency"));
        enableFluxChangeFlash = getBoolean("enableFluxChangeFlash");
        toggleStrafeAndTurnToCursorKey = getInt("toggleStrafeAndTurnToCursorKey");
        warnColor = getColor("warningColor");
        gaugeBackgroundColor = getColor("gaugeBackgroundColor");
        reticleColor = getColor("reticleColor");
        gaugeColor = getColor("softFluxGaugeColor");
        hardFluxColor = getColor("hardFluxGaugeColor");
        dividerColor = getColor("hardFluxDividerColor");

        return true;
    }

    static final float
            MAX_OPACITY = 2,
            MIN_OPACITY = 0,
            FRONT_WIDTH = 22f,
            FRONT_HEIGHT = 32f,
            GLOW_WIDTH = 44f,
            GLOW_HEIGHT = 64f,
            BACK_WIDTH = 11f,
            BACK_HEIGHT = 9f,
            HALF_WIDTH = 5f,
            HALF_HEIGHT = 9f,
            QUARTER_WIDTH = 3f,
            QUARTER_HEIGHT = 9f,
            HARD_BAR_WIDTH = 5f,
            HARD_BAR_HEIGHT = 9f,
            DEFAULT_MAX_LENGTH = 80,
            DEFAULT_MIN_LENGTH = 20,
            DEFAULT_DISTANCE_FULL = 1.0f,
            DEFAULT_DISTANCE_HIDE = 0.1f,
            DEFAULT_BAR_WIDTH = 7f,
            DEFAULT_BAR_BORDER_WIDTH = 1f,
            DEFAULT_RETICLE_TOP_SCALE = 1f,
            DEFAULT_RETICLE_TOP_OFFSET = 0f,
            DEFAULT_RETICLE_TOP_LATERAL_OFFSET = 0f,
            DEFAULT_RETICLE_BODY_LATERAL_OFFSET = 0f,
            TWO_PI = (float)(Math.PI * 2);
    static final int
            ESCAPE_KEY_VALUE = 1;
    static final String
            DEFAULT_SPRITE_SET = "8xNearestEdgeCleaned",
            SPRITE_SET_ROOT = "Root4xLanczos",
            SPRITE_SET_VANILLA = "Vanilla1x",
            SPRITE_SET_4X_LANCZOS = "4xLanczos",
            SPRITE_SET_4X_NEAREST = "4xNearest",
            SPRITE_SET_8X_LANCZOS_EDGE_CLEANED = "8xLanczosEdgeCleaned",
            SPRITE_SET_8X_NEAREST_EDGE_CLEANED = "8xNearestEdgeCleaned",
            SPRITE_SET_AI_GENERATED_FULL_8X = "AIGeneratedFullSet8x";
    static org.lwjgl.input.Cursor hiddenCursor, originalCursor;
    static boolean cursorNeedsReset = false, wasAutoTurnModePriorToActivation = false, errorDisplayed = false;

    float scale = 1f, damageFlash = 0, fluxLastFrame = 0,
            barWidth = DEFAULT_BAR_WIDTH,
            fluxBarBorderWidth = DEFAULT_BAR_BORDER_WIDTH,
            reticleTopScale = DEFAULT_RETICLE_TOP_SCALE,
            reticleTopOffset = DEFAULT_RETICLE_TOP_OFFSET,
            reticleTopLateralOffset = DEFAULT_RETICLE_TOP_LATERAL_OFFSET,
            reticleBodyLateralOffset = DEFAULT_RETICLE_BODY_LATERAL_OFFSET,
            minLength = DEFAULT_MIN_LENGTH,
            maxLength = DEFAULT_MAX_LENGTH,
            minDistance = DEFAULT_DISTANCE_HIDE,
            maxDistance = DEFAULT_DISTANCE_FULL,
            flashStartThreshold = 0.8f,
            flashMaxThreshold = 1f,
            flashStartFrequency = 1.9f,
            flashMaxFrequency = 1.9f;
    int toggleStrafeAndTurnToCursorKey = 37, glowOpacity = 64;
    SpriteAPI frontKeyTurn, frontMouseTurn, back, half, quarter, hardBar, glowKeyTurn, glowMouseTurn;
    CombatEngineAPI engine;
    boolean escapeMenuIsOpen = false, needToLoadSettings = true, showReticle, showReticleWhenInterfaceIsHidden,
            keepBarVisibleAtMinimumDistance, enableFluxChangeFlash = true;
    Vector2f mouse = new Vector2f(), frontCenter = new Vector2f(), bodyCenter = new Vector2f(), at = new Vector2f(), normal = new Vector2f();
    Color reticleColor = Misc.getPositiveHighlightColor(),
            gaugeColor = Misc.getHighlightColor(),
            hardFluxColor = Misc.getNegativeHighlightColor(),
            dividerColor = Misc.getNegativeHighlightColor(),
            warnColor = Color.WHITE,
            gaugeBackgroundColor = Color.BLACK;
    ViewportAPI viewport;
    JSONObject commonData;
    String prevHullId = "";
    String spriteSet = DEFAULT_SPRITE_SET;

    static void resetCursor() {
        try {
            if (originalCursor == null) originalCursor = Mouse.getNativeCursor();

            if(cursorNeedsReset) {
                cursorNeedsReset = false;
                Mouse.setNativeCursor(originalCursor);
                Global.getSettings().setAutoTurnMode(wasAutoTurnModePriorToActivation);
            }
        } catch (Exception e) {
            reportCrash(e);
        }
    }

    public static boolean reportCrash(Exception exception) {
        try {
            String stackTrace = "", message = "Flux reticle encountered an error!\nPlease let the mod author know.";

            for(int i = 0; i < exception.getStackTrace().length; i++) {
                StackTraceElement ste = exception.getStackTrace()[i];
                stackTrace += "    " + ste.toString() + System.lineSeparator();
            }

            Global.getLogger(CombatPlugin.class).error(exception.getMessage() + System.lineSeparator() + stackTrace);

            if (Global.getCombatEngine() != null && Global.getCurrentState() == GameState.COMBAT) {
                Global.getCombatEngine().getCombatUI().addMessage(2, Color.RED, message);

                if(exception.getMessage() != null) {
                    Global.getCombatEngine().getCombatUI().addMessage(1, Color.ORANGE, exception.getMessage());
                }
            } else if (Global.getSector() != null) {
                CampaignUIAPI ui = Global.getSector().getCampaignUI();

                ui.addMessage(message, Color.RED);
                ui.addMessage(exception.getMessage(), Color.ORANGE);
                ui.showConfirmDialog(message + "\n\n" + exception.getMessage(), "Ok", null, null, null);

                if(ui.getCurrentInteractionDialog() != null) ui.getCurrentInteractionDialog().dismiss();
            } else return errorDisplayed = false;

            return errorDisplayed = true;
        } catch (Exception e) {
            return errorDisplayed = false;
        }
    }
    static Color getColor(JSONArray c) throws JSONException {
        return new Color(
                Math.min(255, Math.max(0, c.getInt(0))),
                Math.min(255, Math.max(0, c.getInt(1))),
                Math.min(255, Math.max(0, c.getInt(2))),
                Math.min(255, Math.max(0, c.getInt(3)))
        );
    }
    static Color getColor(Color c, float alphaMult) {
        return new Color(
                Math.min(1, Math.max(0, c.getRed() / 255f)),
                Math.min(1, Math.max(0, c.getGreen() / 255f)),
                Math.min(1, Math.max(0, c.getBlue() / 255f)),
                Math.min(1, Math.max(0, (c.getAlpha() / 255f) * alphaMult))
        );
    }

    public String getFlagshipHullId() {
        return engine.getPlayerShip().getHullSpec().getBaseHullId();
    }
    void drawGaugeSegment(float length, float minLevel, float maxLevel, Color c, float opacity, float colorLerp) {
        minLevel = Math.max(0, Math.min(1, minLevel));
        maxLevel = Math.max(0, Math.min(1, maxLevel));
        if(maxLevel <= minLevel || opacity <= 0) return;

        Vector2f direction = new Vector2f(normal);
        direction.normalise(direction);
        Vector2f perp = new Vector2f(direction.y, -direction.x);
        float width = barWidth * scale;
        float startDistance = length * (1f - maxLevel);
        float endDistance = length * (1f - minLevel);
        Vector2f nearCenter = new Vector2f(bodyCenter.x + direction.x * startDistance, bodyCenter.y + direction.y * startDistance);
        Vector2f farCenter = new Vector2f(bodyCenter.x + direction.x * endDistance, bodyCenter.y + direction.y * endDistance);
        Vector2f nearEdge = new Vector2f(nearCenter.x + perp.x * width * 0.5f, nearCenter.y + perp.y * width * 0.5f);
        Vector2f farEdge = new Vector2f(farCenter.x + perp.x * width * 0.5f, farCenter.y + perp.y * width * 0.5f);
        c = Misc.interpolateColor(c, warnColor, colorLerp);

        glPushAttrib(GL_ALL_ATTRIB_BITS);
        glDisable(GL_TEXTURE_2D);
        glEnable(GL_BLEND);

        glEnable(GL_LINE_SMOOTH);
        glEnable(GL_POLYGON_SMOOTH);
        glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
        glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);

        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glPushMatrix();
        glTranslatef(0.01f, 0.01f, 0);
        glBegin(GL_QUADS);
        {
            glColor4f(c.getRed()/255f, c.getGreen()/255f, c.getBlue()/255f, c.getAlpha()/255f * opacity);

            glVertex2f(farEdge.x, farEdge.y);
            glVertex2f(farEdge.x - perp.x * width, farEdge.y - perp.y * width);
            glVertex2f(nearEdge.x - perp.x * width, nearEdge.y - perp.y * width);
            glVertex2f(nearEdge.x, nearEdge.y);
        }
        glEnd();
        glPopMatrix();
        glDisable(GL_BLEND);
        glPopAttrib();

        glColor4f(1, 1, 1, 1);
    }
    void drawGaugeBorder(float length, Color c, float opacity, float colorLerp) {
        if(length <= 0 || opacity <= 0 || fluxBarBorderWidth <= 0) return;

        Vector2f direction = new Vector2f(normal);
        direction.normalise(direction);
        Vector2f perp = new Vector2f(direction.y, -direction.x);
        float width = barWidth * scale;
        float borderWidth = Math.max(0.5f, fluxBarBorderWidth * scale);
        Vector2f nearCenter = new Vector2f(bodyCenter);
        Vector2f farCenter = new Vector2f(bodyCenter.x + direction.x * length, bodyCenter.y + direction.y * length);
        Vector2f nearEdge = new Vector2f(nearCenter.x + perp.x * width * 0.5f, nearCenter.y + perp.y * width * 0.5f);
        Vector2f farEdge = new Vector2f(farCenter.x + perp.x * width * 0.5f, farCenter.y + perp.y * width * 0.5f);
        c = Misc.interpolateColor(c, warnColor, colorLerp);

        glPushAttrib(GL_ALL_ATTRIB_BITS);
        glDisable(GL_TEXTURE_2D);
        glEnable(GL_BLEND);
        glEnable(GL_LINE_SMOOTH);
        glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glLineWidth(borderWidth);
        glBegin(GL_LINE_LOOP);
        {
            glColor4f(c.getRed()/255f, c.getGreen()/255f, c.getBlue()/255f, c.getAlpha()/255f * opacity);

            glVertex2f(farEdge.x, farEdge.y);
            glVertex2f(farEdge.x - perp.x * width, farEdge.y - perp.y * width);
            glVertex2f(nearEdge.x - perp.x * width, nearEdge.y - perp.y * width);
            glVertex2f(nearEdge.x, nearEdge.y);
        }
        glEnd();
        glDisable(GL_BLEND);
        glPopAttrib();

        glColor4f(1, 1, 1, 1);
    }
    float getFlashAmount(float fluxLevel) {
        float flashProgress = (fluxLevel - flashStartThreshold) / (flashMaxThreshold - flashStartThreshold);
        flashProgress = Math.max(0, Math.min(1, flashProgress));
        float frequency = flashStartFrequency + flashProgress * (flashMaxFrequency - flashStartFrequency);
        float pulse = 0.5f * (1 + (float)Math.sin(engine.getTotalElapsedTime(true) * TWO_PI * frequency));

        return pulse * flashProgress;
    }
    boolean isAutoTurnModeForCurrentFlagshipClass()  throws IOException, JSONException{
        if(engine != null && engine.getPlayerShip() != null && !engine.getCombatUI().isStrafeToggledOn()) {
            return commonData.has(getFlagshipHullId())
                    ? commonData.getBoolean(getFlagshipHullId())
                    : wasAutoTurnModePriorToActivation;
        }

        return false;
    }
    boolean isNotInProperToggleState() {
        return viewport == null || engine == null || engine.isUIShowingDialog() || engine.getCombatUI() == null
                || engine.getCombatUI().isShowingCommandUI()
                || escapeMenuIsOpen || needToLoadSettings || engine.getPlayerShip() == null
                || engine.getPlayerShip().getLocation() == null || Global.getCurrentState() != GameState.COMBAT
                || engine.isCombatOver() || engine.getPlayerShip().isShuttlePod();
    }
    void setAutoTurnModeForCurrentFlagshipClass(boolean useStrafeMode) throws IOException, JSONException {
        if(engine != null && engine.getPlayerShip() != null) {
            commonData.put(getFlagshipHullId(), useStrafeMode);
            Global.getSettings().writeTextFileToCommon(COMMON_DATA_PATH, commonData.toString());
        }
    }

    String getSpriteSetFolder(String configuredSpriteSet) {
        if (SPRITE_SET_ROOT.equals(configuredSpriteSet)) return "";
        if (SPRITE_SET_VANILLA.equals(configuredSpriteSet)) return "backup";
        if (SPRITE_SET_4X_LANCZOS.equals(configuredSpriteSet)) return "upscaled_4x_lanczos";
        if (SPRITE_SET_4X_NEAREST.equals(configuredSpriteSet)) return "upscaled_4x_nearest";
        if (SPRITE_SET_8X_LANCZOS_EDGE_CLEANED.equals(configuredSpriteSet)) return "upscaled_8x_lanczos_edge_cleaned";
        if (SPRITE_SET_AI_GENERATED_FULL_8X.equals(configuredSpriteSet)) return "ai_generated_full_set_8x";
        return "upscaled_8x_nearest_edge_cleaned";
    }

    SpriteAPI loadSpriteFromSet(String configuredSpriteSet, String fileName) throws IOException {
        String folder = getSpriteSetFolder(configuredSpriteSet);
        String path = folder.isEmpty()
                ? "shat_fr/graphics/" + fileName
                : "shat_fr/graphics/" + folder + "/" + fileName;

        Global.getSettings().loadTexture(path);
        return Global.getSettings().getSprite(path);
    }

    void loadSpritesForSet(String configuredSpriteSet) throws IOException {
        frontKeyTurn = loadSpriteFromSet(configuredSpriteSet, "frontKeyTurn.png");
        frontMouseTurn = loadSpriteFromSet(configuredSpriteSet, "frontMouseTurn.png");
        glowKeyTurn = loadSpriteFromSet(configuredSpriteSet, "glowKeyTurn.png");
        glowMouseTurn = loadSpriteFromSet(configuredSpriteSet, "glowMouseTurn.png");
        back = loadSpriteFromSet(configuredSpriteSet, "back.png");
        half = loadSpriteFromSet(configuredSpriteSet, "half.png");
        quarter = loadSpriteFromSet(configuredSpriteSet, "quarter.png");
        hardBar = loadSpriteFromSet(configuredSpriteSet, "hardBar.png");
    }

    @Override
    public void init(CombatEngineAPI engine) {
        try {
            this.engine = engine;
            errorDisplayed = false;

            resetCursor();

            loadSpritesForSet(DEFAULT_SPRITE_SET);


            try {
                commonData = new JSONObject(Global.getSettings().readTextFileFromCommon(COMMON_DATA_PATH));
            } catch (Exception e) {
                Global.getSettings().writeTextFileToCommon(COMMON_DATA_PATH, "{}");
                commonData = new JSONObject(Global.getSettings().readTextFileFromCommon(COMMON_DATA_PATH));
            }
        } catch (Exception e) { reportCrash(e); }
    }

    @Override
    public void processInputPreCoreControls(float amount, List<InputEventAPI> events) {
        try {
            if (engine == null) return;

            if (!engine.isUIShowingDialog()) escapeMenuIsOpen = false;

            for (InputEventAPI e : events) {
                if (e.isConsumed() || !e.isKeyDownEvent()) continue;

                if (e.getEventValue() == ESCAPE_KEY_VALUE) {
                    escapeMenuIsOpen = true;
                } else if (e.getEventValue() == toggleStrafeAndTurnToCursorKey
                        && !engine.isUIShowingDialog()
                        && !Global.getSettings().isStrafeKeyAToggle()) {

                    boolean isAutoTurnMode = !Global.getSettings().isAutoTurnMode();
                    Global.getSettings().setAutoTurnMode(isAutoTurnMode);
                    setAutoTurnModeForCurrentFlagshipClass(isAutoTurnMode);
                    Global.getSoundPlayer().playUISound(Global.getSettings().isAutoTurnMode()
                            ? "shat_fr_turn_to_cursor_on"
                            : "shat_fr_turn_to_cursor_off", 1, 1);
                }
            }
        } catch (Exception e) { reportCrash(e); }
    }

    @Override
    public void renderInUICoords(ViewportAPI viewport) {
        try {
            this.viewport = viewport;
        } catch (Exception e) { reportCrash(e); }
    }

    @Override
    public void renderInWorldCoords(ViewportAPI viewport) { }

    @Override
    public void advance(float amount, java.util.List<InputEventAPI> events) {
        try {
            if(engine == null || errorDisplayed) return;

            if(needToLoadSettings) {
                readSettings();

                float topScale = scale * reticleTopScale;
                frontKeyTurn.setSize(FRONT_WIDTH * topScale, FRONT_HEIGHT * topScale);
                frontMouseTurn.setSize(FRONT_WIDTH * topScale, FRONT_HEIGHT * topScale);
                glowKeyTurn.setSize(GLOW_WIDTH * topScale, GLOW_HEIGHT * topScale);
                glowMouseTurn.setSize(GLOW_WIDTH * topScale, GLOW_HEIGHT * topScale);
                back.setSize(BACK_WIDTH * scale, BACK_HEIGHT * scale);
                half.setSize(HALF_WIDTH * scale, HALF_HEIGHT * scale);
                quarter.setSize(QUARTER_WIDTH * scale, QUARTER_HEIGHT * scale);
                hardBar.setSize(HARD_BAR_WIDTH * scale, HARD_BAR_HEIGHT * scale);

                needToLoadSettings = false;
            }

            if(isNotInProperToggleState()) {
                resetCursor();
            } else {
                if(!cursorNeedsReset) {
                    wasAutoTurnModePriorToActivation = Global.getSettings().isAutoTurnMode();
                }

                if(Global.getSettings().isStrafeKeyAToggle()) {
                    prevHullId = "";
                } else if(!cursorNeedsReset || !prevHullId.equals(getFlagshipHullId())) {
                    Global.getSettings().setAutoTurnMode(isAutoTurnModeForCurrentFlagshipClass());
                    prevHullId = getFlagshipHullId();
                }

                cursorNeedsReset = true;

                if(!showReticle) {
                    return;
                } else if(!engine.isUIShowingHUD() && !showReticleWhenInterfaceIsHidden) {
                    resetCursor();

                    return;
                }

                if(hiddenCursor == null) hiddenCursor = new Cursor(1, 1, 0, 0, 1, BufferUtils.createIntBuffer(1), null);

                mouse.set(Global.getSettings().getMouseX(), Global.getSettings().getMouseY());
                at.set(engine.getPlayerShip().getLocation());
                at.x = viewport.convertWorldXtoScreenX(at.x);
                at.y = viewport.convertWorldYtoScreenY(at.y);
                Vector2f.sub(at, mouse, normal);

                float f = Misc.getDistance(mouse, at) / viewport.getVisibleHeight() * 2;
                f -= minDistance;
                f = Math.max(0, Math.min(1, f / (maxDistance - minDistance) * viewport.getViewMult()));

                float flux = engine.getPlayerShip().getFluxLevel();
                float opacity = keepBarVisibleAtMinimumDistance
                        ? 1f
                        : Math.max(MIN_OPACITY, Math.min(1, f * MAX_OPACITY));
                float hard = engine.getPlayerShip().getHardFluxLevel();
                float softOnly = Math.max(0, flux - hard);
                float length = (minLength + f * (maxLength - minLength)) * scale;
                float aimAngle = Misc.getAngleInDegrees(at, mouse);
                if (normal.lengthSquared() <= 0.0001f) {
                    double radians = Math.toRadians(aimAngle + 180f);
                    normal.set((float) Math.cos(radians), (float) Math.sin(radians));
                }
                Vector2f frontOffsetDirection = new Vector2f(normal);
                frontOffsetDirection.normalise();
                Vector2f frontRightDirection = new Vector2f(-frontOffsetDirection.y, frontOffsetDirection.x);
                bodyCenter.set(
                        mouse.x + frontRightDirection.x * reticleBodyLateralOffset * scale,
                        mouse.y + frontRightDirection.y * reticleBodyLateralOffset * scale);
                frontCenter.set(
                        mouse.x - frontOffsetDirection.x * reticleTopOffset * scale
                                + frontRightDirection.x * reticleTopLateralOffset * scale,
                        mouse.y - frontOffsetDirection.y * reticleTopOffset * scale
                                + frontRightDirection.y * reticleTopLateralOffset * scale);
                float warnness = getFlashAmount(flux);
                Color clr = new Color(reticleColor.getRGB());
                Color glowClr = new Color(clr.getRed(), clr.getGreen(), clr.getBlue(), glowOpacity);
                SpriteAPI front, glow;

                damageFlash = enableFluxChangeFlash
                        ? Math.max(0, Math.min(1, damageFlash - amount * 1 + (flux - fluxLastFrame) * 5))
                        : 0;
                fluxLastFrame = flux;
                warnness = Math.max(0, Math.min(1, warnness + damageFlash));

                clr = Misc.interpolateColor(clr, warnColor, warnness);

                if(Global.getSettings().isStrafeKeyAToggle()) {
                    if(engine.getCombatUI().isStrafeToggledOn()) {
                        front = frontMouseTurn;
                        glow = glowMouseTurn;
                    } else {
                        front = frontKeyTurn;
                        glow = glowKeyTurn;
                    }
                } else if(Global.getSettings().isAutoTurnMode() ^ org.lwjgl.input.Keyboard.isKeyDown(Keyboard.KEY_LSHIFT)) {
                    front = frontMouseTurn;
                    glow = glowMouseTurn;
                } else {
                    front = frontKeyTurn;
                    glow = glowKeyTurn;
                }

                glPushMatrix();
                glLoadIdentity();
                glOrtho(0, Global.getSettings().getScreenWidth(), 0, Global.getSettings().getScreenHeight(), -1, 1);

                glBlendFunc(GL_ONE, GL_ONE);

                glow.setColor(glowClr);
                glow.setAngle(aimAngle);
                glow.renderAtCenter(frontCenter.x, frontCenter.y);

                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

                if(opacity > 0) {
                    drawGaugeSegment(length, 0, 1, gaugeBackgroundColor, opacity, 0);
                    drawGaugeBorder(length, reticleColor, opacity, warnness);
                }

                front.setColor(clr);
                front.setAngle(aimAngle);
                front.renderAtCenter(frontCenter.x, frontCenter.y);

                Mouse.setNativeCursor(hiddenCursor);

                if(opacity > 0) {
                    clr = new Color(clr.getRed(), clr.getGreen(), clr.getBlue(), (int) Math.min(255, clr.getAlpha() * opacity));

                    normal.normalise().scale(length * 0.25f);
                    quarter.setColor(clr);
                    quarter.setAngle(aimAngle);
                    quarter.renderAtCenter(normal.x + bodyCenter.x, normal.y + bodyCenter.y);

                    normal.normalise().scale(length * 0.5f);
                    half.setColor(clr);
                    half.setAngle(aimAngle);
                    half.renderAtCenter(normal.x + bodyCenter.x, normal.y + bodyCenter.y);

                    normal.normalise().scale(length * 0.75f);
                    quarter.setColor(clr);
                    quarter.setAngle(aimAngle);
                    quarter.renderAtCenter(normal.x + bodyCenter.x, normal.y + bodyCenter.y);

                    normal.normalise().scale(length);
                    back.setColor(clr);
                    back.setAngle(aimAngle);
                    back.renderAtCenter(normal.x + bodyCenter.x, normal.y + bodyCenter.y);

                    clr = new Color(dividerColor.getRed(), dividerColor.getGreen(), dividerColor.getBlue(),
                            (int) Math.max(0, Math.min(255, dividerColor.getAlpha() * opacity * Math.min(1f, hard * 10f))));
                    clr = Misc.interpolateColor(clr, warnColor, warnness);

                    normal.normalise().scale(length * (1f - hard));
                    hardBar.setColor(clr);
                    hardBar.setAngle(aimAngle);
                    hardBar.renderAtCenter(normal.x + bodyCenter.x, normal.y + bodyCenter.y);

                    drawGaugeSegment(length, hard, hard + softOnly, gaugeColor, opacity, warnness);
                    drawGaugeSegment(length, 0, hard, hardFluxColor, opacity, warnness);
                }

                glPopMatrix();
            }
        } catch (Exception e) {
            needToLoadSettings = !reportCrash(e);
        }
    }
}
