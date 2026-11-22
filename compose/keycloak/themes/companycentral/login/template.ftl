<#import "footer.ftl" as loginFooter>
<#--
  CompanyCentral page layout for every login-flow page (sign-in, registration,
  password reset, required actions, errors). Same macro and sections as
  Keycloak's base template.ftl, so all of Keycloak's page templates work with it.
-->
<#macro registrationLayout bodyClass="" displayInfo=false displayMessage=true displayRequiredFields=false>
<!DOCTYPE html>
<html class="${properties.kcHtmlClass!}" lang="${lang}"<#if realm.internationalizationEnabled> dir="${(locale.rtl)?then('rtl','ltr')}"</#if>>
<head>
    <meta charset="utf-8">
    <#if properties.meta?has_content>
        <#list properties.meta?split(' ') as meta>
            <meta name="${meta?split('==')[0]}" content="${meta?split('==')[1]}"/>
        </#list>
    </#if>
    <meta name="robots" content="noindex, nofollow">
    <title>${title!}</title>
    <link rel="icon" href="${url.resourcesPath}/img/favicon.svg" type="image/svg+xml">
    <#if properties.styles?has_content>
        <#list properties.styles?split(' ') as style>
            <link href="${url.resourcesPath}/${style}" rel="stylesheet" />
        </#list>
    </#if>
    <script type="importmap">
        { "imports": { "rfc4648": "${url.resourcesCommonPath}/vendor/rfc4648/rfc4648.js" } }
    </script>
    <#if scripts??>
        <#list scripts as script>
            <script src="${script}" type="text/javascript"></script>
        </#list>
    </#if>
    <#-- Keycloak's session checks: finish here when sign-in completes in another tab -->
    <script type="module">
        <#outputformat "JavaScript">
        import { startSessionPolling } from ${(url.resourcesPath + "/js/authChecker.js")?c};
        startSessionPolling(${url.ssoLoginInOtherTabsUrl?c});
        </#outputformat>
    </script>
    <#if authenticationSession??>
        <script type="module">
            <#outputformat "JavaScript">
            import { checkAuthSession } from ${(url.resourcesPath + "/js/authChecker.js")?c};
            checkAuthSession(${authenticationSession.authSessionIdHash?c});
            </#outputformat>
        </script>
    </#if>
    <script type="module">
        // Single-use links (identity providers): disable after the first click
        document.addEventListener("click", (event) => {
            const link = event.target.closest("a[data-once-link]");
            if (!link) return;
            if (link.getAttribute("aria-disabled") === "true") { event.preventDefault(); return; }
            link.setAttribute("aria-disabled", "true");
        });
    </script>
</head>

<body class="${properties.kcBodyClass!} ${bodyClass}" data-page-id="login-${pageId}">
<div class="${properties.kcLoginClass!}">
    <aside class="cc-brand" aria-hidden="true">
        <div class="cc-brand__inner">
            <p class="cc-logo"><span class="cc-logo__mark"></span>CompanyCentral</p>
            <p class="cc-brand__tagline">${msg("ccTagline")}</p>
            <ul class="cc-brand__points">
                <li>${msg("ccPointPlanning")}</li>
                <li>${msg("ccPointInventory")}</li>
                <li>${msg("ccPointProduction")}</li>
            </ul>
        </div>
    </aside>

    <main class="cc-main">
        <div class="cc-topbar">
            <p class="cc-logo cc-logo--compact"><span class="cc-logo__mark"></span>CompanyCentral</p>
            <#if realm.internationalizationEnabled && locale.supported?size gt 1>
                <nav class="cc-locales" aria-label="${msg("languages")}">
                    <#list locale.supported as l>
                        <#if l.languageTag == locale.currentLanguageTag>
                            <span class="cc-locales__item" aria-current="true">${l.languageTag?upper_case}</span>
                        <#else>
                            <a class="cc-locales__item" href="${l.url}" lang="${l.languageTag}" title="${l.label}">${l.languageTag?upper_case}</a>
                        </#if>
                    </#list>
                </nav>
            </#if>
        </div>

        <section class="${properties.kcFormCardClass!}" aria-labelledby="kc-page-title">
            <header class="${properties.kcFormHeaderClass!}">
                <#if !(auth?has_content && auth.showUsername() && !auth.showResetCredentials())>
                    <h1 id="kc-page-title"><#nested "header"></h1>
                    <#if displayRequiredFields>
                        <p class="cc-required-note"><span class="required">*</span> ${msg("requiredFields")}</p>
                    </#if>
                <#else>
                    <#nested "show-username">
                    <div id="kc-username" class="cc-username">
                        <span id="kc-attempted-username">${auth.attemptedUsername}</span>
                        <a id="reset-login" href="${url.loginRestartFlowUrl}">${msg("ccChangeUser")}</a>
                    </div>
                    <#if displayRequiredFields>
                        <p class="cc-required-note"><span class="required">*</span> ${msg("requiredFields")}</p>
                    </#if>
                </#if>
            </header>

            <div id="kc-content">
                <#-- App-initiated actions should not see warnings about completing the action during login -->
                <#if displayMessage && message?has_content && (message.type != 'warning' || !isAppInitiatedAction??)>
                    <div class="${properties.kcAlertClass!} cc-alert--${message.type}" role="<#if message.type = 'error'>alert<#else>status</#if>">
                        <span class="${properties.kcAlertTitleClass!}">${kcSanitize(message.summary)?no_esc}</span>
                    </div>
                </#if>

                <#nested "form">

                <#if auth?has_content && auth.showTryAnotherWayLink()>
                    <form id="kc-select-try-another-way-form" action="${url.loginAction}" method="post">
                        <input type="hidden" name="tryAnotherWay" value="on"/>
                        <button type="submit" class="cc-link-button" id="try-another-way">${msg("doTryAnotherWay")}</button>
                    </form>
                </#if>

                <#if switchOrganizationEnabled?? && switchOrganizationEnabled>
                    <form id="kc-switch-organization-form" action="${url.loginAction}" method="post">
                        <input type="hidden" name="switchOrganization" value="true"/>
                        <button type="submit" class="cc-link-button" id="switch-organization">${msg("doSwitchOrganization")}</button>
                    </form>
                </#if>

                <#nested "socialProviders">

                <#if displayInfo>
                    <div id="kc-info" class="${properties.kcSignUpClass!}">
                        <div id="kc-info-wrapper" class="${properties.kcInfoAreaWrapperClass!}">
                            <#nested "info">
                        </div>
                    </div>
                </#if>
            </div>
            <@loginFooter.content/>
        </section>

        <p class="cc-footnote">${msg("ccFootnote")}</p>
    </main>
</div>
</body>
</html>
</#macro>
