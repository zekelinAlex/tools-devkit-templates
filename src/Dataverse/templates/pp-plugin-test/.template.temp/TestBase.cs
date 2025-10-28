using Microsoft.VisualStudio.TestTools.UnitTesting;
using DG.Tools.XrmMockup;
using Microsoft.Xrm.Sdk;

[TestClass]
public class TestBase
{
    protected static XrmMockup365 Crm;
    protected IOrganizationService orgAdminUIService;
    protected IOrganizationService orgAdminService;

    [AssemblyInitialize]
    public static void Init(TestContext _)
    {
        Crm = XrmMockup365.GetInstance(new XrmMockupSettings
        {
            BasePluginTypes = new[] { typeof(pluginnamespaceexample.PluginBase) },
            EnableProxyTypes = true,
        });
    }

    [TestInitialize]
    public void PerTestInit()
    {
        orgAdminUIService = Crm.GetAdminService(
            new MockupServiceSettings(true, false, MockupServiceSettings.Role.UI));
        orgAdminService = Crm.GetAdminService();
    }

    [TestCleanup]
    public void Cleanup() => Crm.ResetEnvironment();
}
