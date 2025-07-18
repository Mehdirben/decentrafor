-- Forum Database Schema for Supabase
-- This file contains the database structure for the educational forum feature

-- Enable Row Level Security
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;

-- Create forum_categories table
CREATE TABLE IF NOT EXISTS forum_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    icon VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create forum_topics table
CREATE TABLE IF NOT EXISTS forum_topics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category_id UUID NOT NULL REFERENCES forum_categories(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    views_count INTEGER DEFAULT 0,
    is_pinned BOOLEAN DEFAULT FALSE,
    is_locked BOOLEAN DEFAULT FALSE
);

-- Create forum_posts table
CREATE TABLE IF NOT EXISTS forum_posts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    content TEXT NOT NULL,
    topic_id UUID NOT NULL REFERENCES forum_topics(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    parent_post_id UUID REFERENCES forum_posts(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_edited BOOLEAN DEFAULT FALSE,
    attachments JSONB DEFAULT '[]'
);

-- Create forum_post_likes table
CREATE TABLE IF NOT EXISTS forum_post_likes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    post_id UUID NOT NULL REFERENCES forum_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(post_id, user_id)
);

-- Create profiles table if it doesn't exist (for user display names)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    full_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_forum_topics_category_id ON forum_topics(category_id);
CREATE INDEX IF NOT EXISTS idx_forum_topics_author_id ON forum_topics(author_id);
CREATE INDEX IF NOT EXISTS idx_forum_topics_created_at ON forum_topics(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_forum_topics_pinned ON forum_topics(is_pinned DESC, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_forum_posts_topic_id ON forum_posts(topic_id);
CREATE INDEX IF NOT EXISTS idx_forum_posts_author_id ON forum_posts(author_id);
CREATE INDEX IF NOT EXISTS idx_forum_posts_created_at ON forum_posts(created_at);
CREATE INDEX IF NOT EXISTS idx_forum_posts_parent_id ON forum_posts(parent_post_id);

CREATE INDEX IF NOT EXISTS idx_forum_post_likes_post_id ON forum_post_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_forum_post_likes_user_id ON forum_post_likes(user_id);

-- Create updated_at triggers
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER forum_categories_updated_at
    BEFORE UPDATE ON forum_categories
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER forum_topics_updated_at
    BEFORE UPDATE ON forum_topics
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER forum_posts_updated_at
    BEFORE UPDATE ON forum_posts
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- Row Level Security Policies

-- Forum Categories (public read, admin write)
ALTER TABLE forum_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view forum categories" ON forum_categories
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create categories" ON forum_categories
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Only category author can update" ON forum_categories
    FOR UPDATE USING (auth.uid() IS NOT NULL);

-- Forum Topics (public read, authenticated write)
ALTER TABLE forum_topics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view forum topics" ON forum_topics
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create topics" ON forum_topics
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = author_id);

CREATE POLICY "Only topic author can update" ON forum_topics
    FOR UPDATE USING (auth.uid() = author_id);

CREATE POLICY "Only topic author can delete" ON forum_topics
    FOR DELETE USING (auth.uid() = author_id);

-- Forum Posts (public read, authenticated write)
ALTER TABLE forum_posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view forum posts" ON forum_posts
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create posts" ON forum_posts
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = author_id);

CREATE POLICY "Only post author can update" ON forum_posts
    FOR UPDATE USING (auth.uid() = author_id);

CREATE POLICY "Only post author can delete" ON forum_posts
    FOR DELETE USING (auth.uid() = author_id);

-- Forum Post Likes (authenticated users only)
ALTER TABLE forum_post_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all likes" ON forum_post_likes
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can manage their likes" ON forum_post_likes
    FOR ALL USING (auth.uid() = user_id);

-- Profiles (public read, own write)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view profiles" ON profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR ALL USING (auth.uid() = id);

-- Function to handle new user profile creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, full_name)
    VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'full_name', 'Anonymous User'));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user profile creation
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Insert some sample forum categories
INSERT INTO forum_categories (name, description, icon) VALUES
('Mathematics', 'Discuss mathematical concepts, problems, and solutions', 'math'),
('Science', 'Share scientific discoveries, experiments, and theories', 'science'),
('Literature', 'Explore books, poetry, writing techniques, and literary analysis', 'literature'),
('History', 'Learn and discuss historical events, figures, and cultures', 'history'),
('Technology', 'Computer science, programming, and technology discussions', 'technology'),
('Art & Design', 'Creative arts, design principles, and artistic techniques', 'art'),
('Language Learning', 'Practice languages, grammar, and cultural exchange', 'language'),
('General Discussion', 'Open discussions about education and learning', 'general')
ON CONFLICT DO NOTHING;

-- Create a view for topic statistics
CREATE OR REPLACE VIEW forum_topic_stats AS
SELECT 
    t.id,
    t.title,
    t.description,
    t.category_id,
    t.author_id,
    t.created_at,
    t.updated_at,
    t.views_count,
    t.is_pinned,
    t.is_locked,
    p.full_name as author_name,
    COUNT(fp.id) as posts_count,
    MAX(fp.created_at) as last_post_at
FROM forum_topics t
LEFT JOIN profiles p ON t.author_id = p.id
LEFT JOIN forum_posts fp ON t.id = fp.topic_id
GROUP BY t.id, t.title, t.description, t.category_id, t.author_id, t.created_at, t.updated_at, t.views_count, t.is_pinned, t.is_locked, p.full_name;

-- Create a view for category statistics
CREATE OR REPLACE VIEW forum_category_stats AS
SELECT 
    c.id,
    c.name,
    c.description,
    c.icon,
    c.created_at,
    c.updated_at,
    COUNT(DISTINCT t.id) as topics_count,
    COUNT(fp.id) as posts_count
FROM forum_categories c
LEFT JOIN forum_topics t ON c.id = t.category_id
LEFT JOIN forum_posts fp ON t.id = fp.topic_id
GROUP BY c.id, c.name, c.description, c.icon, c.created_at, c.updated_at;
