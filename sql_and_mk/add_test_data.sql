-- Simple script to add test data to existing pdfs table
-- Run this if you already have the pdfs table set up

-- Insert test data
INSERT INTO pdfs (title, description, file_name, file_url, file_size, category, tags) VALUES
(
    'Flutter Development Guide',
    'A comprehensive guide to Flutter development covering widgets, state management, and best practices.',
    'flutter_guide.pdf',
    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    2450000,
    'Technology',
    ARRAY['flutter', 'development', 'guide']
),
(
    'Business Strategy 2024',
    'Annual business strategy document outlining goals, objectives, and key performance indicators.',
    'business_strategy_2024.pdf',
    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    1890000,
    'Business',
    ARRAY['strategy', 'business', '2024']
),
(
    'Introduction to Machine Learning',
    'Educational material covering the basics of machine learning algorithms and applications.',
    'ml_intro.pdf',
    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    3200000,
    'Education',
    ARRAY['machine learning', 'education', 'ai']
),
(
    'Health and Wellness Report',
    'Annual health and wellness report with statistics and recommendations for healthy living.',
    'health_wellness_2024.pdf',
    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    1560000,
    'Health',
    ARRAY['health', 'wellness', 'report']
),
(
    'Science Research Paper',
    'Research paper on renewable energy sources and their impact on climate change.',
    'renewable_energy_research.pdf',
    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    4100000,
    'Science',
    ARRAY['research', 'renewable energy', 'climate']
);
