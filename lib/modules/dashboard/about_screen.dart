import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/dashboard/store/home_store.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../../helpers/app_tokens.dart';
import '../login/store/login_store.dart';
import '../widgets/no_internet_connection.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  State<AboutScreen> createState() => _AboutScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const AboutScreen(),
    );
  }
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  void initState() {
    super.initState();
    settingsData();
  }

  Future<void> settingsData() async {
    final store = Provider.of<LoginStore>(context, listen: false);
    await store.onGetSettingsData();
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<HomeStore>(context, listen: false);
    final loginStore = Provider.of<LoginStore>(context, listen: false);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppTokens.scaffold(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTokens.ink(context), size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text("Contact & support", style: AppTokens.titleLg(context)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Observer(
          builder: (_) {
            if (store.isLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: AppTokens.accent(context),
                ),
              );
            }
            if (!store.isConnected) return const NoInternetScreen();
            if (loginStore.isLoadingSettings) {
              return const SizedBox.shrink();
            }
            final email = loginStore.settingsData.value?.email ?? "";
            final phone = loginStore.settingsData.value?.phone ?? "";
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppTokens.s24, AppTokens.s24, AppTokens.s24, AppTokens.s24),
              children: [
                // Apple-style hero with brand-mark + product name.
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: AppTokens.radius16,
                      child: Image.asset(
                        'assets/image/app_icon.jpg',
                        width: 64, height: 64, fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: AppTokens.s16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Sushruta LGS",
                              style: AppTokens.titleLg(context)),
                          const SizedBox(height: 2),
                          Text(
                            "We're here to help — pick a channel.",
                            style: AppTokens.body(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s32),
                if (email.isNotEmpty)
                  _ContactTile(
                    icon: Icons.mail_outline_rounded,
                    title: "Email",
                    subtitle: email,
                    onTap: () => _launchEmail(email),
                  ),
                if (email.isNotEmpty && phone.isNotEmpty)
                  const SizedBox(height: AppTokens.s8),
                if (phone.isNotEmpty)
                  _ContactTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: "WhatsApp",
                    subtitle: "+91 $phone",
                    onTap: () => _launchWhatsApp(phone),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  _launchEmail(String email) async {
    final Uri _emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunch(_emailLaunchUri.toString())) {
      await launch(_emailLaunchUri.toString());
    } else {
      throw 'Could not launch email';
    }
  }

  _launchWhatsApp(String phone) async {
    final Uri whatsAppLaunchUri =
        Uri(scheme: 'https', host: 'wa.me', path: "91$phone");
    if (await canLaunch(whatsAppLaunchUri.toString())) {
      await launch(whatsAppLaunchUri.toString());
    } else {
      throw 'Could not launch WhatsApp';
    }
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : super(key: key);

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.surface(context),
      borderRadius: AppTokens.radius16,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTokens.radius16,
        child: Container(
          padding: const EdgeInsets.all(AppTokens.s16),
          decoration: BoxDecoration(
            borderRadius: AppTokens.radius16,
            border: Border.all(
              color: AppTokens.border(context),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppTokens.accent(context),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTokens.titleSm(context),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTokens.caption(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppTokens.muted(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
