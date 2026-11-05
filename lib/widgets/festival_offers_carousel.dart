import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../models/festival_offer.dart';
import '../providers/festival_offers_provider.dart';
import '../theme/app_theme.dart';
import '../screens/buyer/category_screen.dart';

class FestivalOffersCarousel extends ConsumerStatefulWidget {
  const FestivalOffersCarousel({super.key});

  @override
  ConsumerState<FestivalOffersCarousel> createState() => _FestivalOffersCarouselState();
}

class _FestivalOffersCarouselState extends ConsumerState<FestivalOffersCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      final offers = ref.read(festivalOffersProvider).valueOrNull ?? FestivalOffer.defaultOffers;
      if (offers.isEmpty) return;

      final nextPage = (_currentPage + 1) % offers.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offersAsync = ref.watch(festivalOffersProvider);
    final offers = offersAsync.valueOrNull ?? FestivalOffer.defaultOffers;

    if (offers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 195,
          child: PageView.builder(
            controller: _pageController,
            itemCount: offers.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final offer = offers[index];
              return _buildOfferSlide(context, offer);
            },
          ),
        ),
        const SizedBox(height: 10),
        // Smooth Page Indicator Dots
        Center(
          child: SmoothPageIndicator(
            controller: _pageController,
            count: offers.length,
            effect: const ExpandingDotsEffect(
              dotHeight: 6,
              dotWidth: 6,
              expansionFactor: 3.5,
              activeDotColor: Color(0xFF5A1629),
              dotColor: Color(0xFFDCD2C9),
              spacing: 5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfferSlide(BuildContext context, FestivalOffer offer) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: offer.backgroundGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: offer.backgroundGradient.first.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background subtle artisan pattern / icon
            Positioned(
              right: -15,
              bottom: -15,
              child: Opacity(
                opacity: 0.12,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 150,
                  color: Colors.white,
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Badge & Discount
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD64438),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          offer.badge,
                          style: GoogleFonts.montserrat(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (offer.discountText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: offer.accentColor.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: offer.accentColor, width: 1),
                          ),
                          child: Text(
                            offer.discountText!,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: offer.accentColor,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Middle: Title & Subtitle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.title,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        offer.subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: const Color(0xFFFAF3EC).withValues(alpha: 0.9),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  // Bottom Row: Coupon code pill + Shop button
                  Row(
                    children: [
                      if (offer.couponCode != null)
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: offer.couponCode!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🎉 Coupon "${offer.couponCode}" copied to clipboard! Apply at checkout.'),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.confirmation_number_outlined, color: Colors.white, size: 13),
                                const SizedBox(width: 5),
                                Text(
                                  'Use: ${offer.couponCode}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.copy_rounded, color: Colors.white70, size: 11),
                              ],
                            ),
                          ),
                        ),

                      const Spacer(),

                      // Action Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF5A1629),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CategoryScreen(categoryId: offer.categoryId),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Claim Offer',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                                color: const Color(0xFF5A1629),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF5A1629)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

