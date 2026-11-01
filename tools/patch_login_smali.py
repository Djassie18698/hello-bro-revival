"""Points the APK's account window (Gumptech SDK) at the revival server: com/gumptech/sdk/c/a/b.smali reads server.url from
assets/baseconfig.json instead of using http://api.gumptech.com. Used once to make release/classes-revival.dex:
  java -jar apktool.jar d -r -o dec <apk> ; python -I tools/patch_login_smali.py dec/smali/com/gumptech/sdk/c/a/b.smali ;
  java -jar apktool.jar b -o built.apk dec ; take classes.dex from built.apk."""
import sys
p = sys.argv[1]
s = open(p, encoding='utf8').read()
old = """    .line 31
    :cond_0
    const-string v0, "DefaultRestclient"
"""
new = """    .line 31
    :cond_0
    invoke-static {p0}, Lcom/gumptech/sdk/c/a/b;->revivalUrl(Landroid/content/Context;)Ljava/lang/String;

    move-result-object v0

    if-eqz v0, :cond_revival

    sput-object v0, Lcom/gumptech/sdk/c/a/b;->c:Ljava/lang/String;

    :cond_revival
    const-string v0, "DefaultRestclient"
"""
assert old in s
s = s.replace(old, new, 1)
s += """
# Revival server: the account login goes to the game server named in assets/baseconfig.json (server.url), not api.gumptech.com.
.method public static revivalUrl(Landroid/content/Context;)Ljava/lang/String;
    .locals 4

    :try_start_0
    invoke-virtual {p0}, Landroid/content/Context;->getAssets()Landroid/content/res/AssetManager;

    move-result-object v0

    const-string v1, "baseconfig.json"

    invoke-virtual {v0, v1}, Landroid/content/res/AssetManager;->open(Ljava/lang/String;)Ljava/io/InputStream;

    move-result-object v0

    new-instance v1, Ljava/util/Scanner;

    invoke-direct {v1, v0}, Ljava/util/Scanner;-><init>(Ljava/io/InputStream;)V

    const-string v2, "\\\\A"

    invoke-virtual {v1, v2}, Ljava/util/Scanner;->useDelimiter(Ljava/lang/String;)Ljava/util/Scanner;

    move-result-object v1

    invoke-virtual {v1}, Ljava/util/Scanner;->next()Ljava/lang/String;

    move-result-object v1

    new-instance v2, Lorg/json/JSONArray;

    invoke-direct {v2, v1}, Lorg/json/JSONArray;-><init>(Ljava/lang/String;)V

    const/4 v3, 0x0

    invoke-virtual {v2, v3}, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;

    move-result-object v2

    const-string v3, "server"

    invoke-virtual {v2, v3}, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;

    move-result-object v2

    const-string v3, "url"

    invoke-virtual {v2, v3}, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v0
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    return-object v0

    :catch_0
    const/4 v0, 0x0

    return-object v0
.end method
"""
open(p, 'w', encoding='utf8').write(s)
print('patched')
