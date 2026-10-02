// ตัวอย่าง — วางที่ microservices/user-service/src/models/star-card.model.js
// ตาราง star_cards (SQL สำหรับทีม ops อยู่ใน ./star-card.sql)
import moment from 'moment'

export default (sequelize, { DATE, JSONB, INTEGER, SMALLINT, STRING, BOOLEAN }, dbConfig, Sequelize) => {
  const fnDateNow = () => moment().utcOffset('+07:00').format('YYYY-MM-DDTHH:mm:ss+07:00')

  const attributes = {
    id: {
      allowNull: false,
      autoIncrement: true,
      primaryKey: true,
      type: INTEGER
    },
    userId: {
      field: 'user_id',
      type: INTEGER,
      allowNull: false
    },
    // ท้ายลิงก์เฉพาะใบ เช่น salehere.co.th/star/{slug}/{shortId}
    shortId: {
      field: 'short_id',
      type: STRING(8),
      allowNull: false,
      unique: true
    },
    format: {
      type: STRING(16),
      allowNull: false,
      validate: { isIn: { args: [['portfolio', 'story']], msg: 'รูปแบบการ์ดไม่ถูกต้อง' } }
    },
    name: {
      type: STRING(60),
      allowNull: false,
      defaultValue: ''
    },
    // ใบที่เปิดให้คนอื่นเห็นจากลิงก์โปรไฟล์ — หนึ่งคนมีได้ใบเดียว (unique index ใน SQL)
    isPrimary: {
      field: 'is_primary',
      type: BOOLEAN,
      allowNull: false,
      defaultValue: false
    },
    // เริ่มจาก template ไหน (designed.3119bb) — ไว้ดูสถิติว่าแบบไหนคนใช้เยอะ
    templateId: {
      field: 'template_id',
      type: STRING(40)
    },
    schemaVersion: {
      field: 'schema_version',
      type: SMALLINT,
      allowNull: false,
      defaultValue: 1
    },
    // ผังการ์ดฉบับร่าง — ดูตัวอย่างเต็มที่ ./example-doc.json
    // เก็บทั้งก้อนตามที่แอปส่งมา ห้ามตัด kind/ฟิลด์ที่ server ไม่รู้จักทิ้ง
    draftDoc: {
      field: 'draft_doc',
      type: JSONB,
      allowNull: false
    },
    // ขึ้นทีละ 1 ทุกครั้งที่บันทึก — แอปส่ง baseRev มา ถ้าไม่ตรงแปลว่ามีอีกเครื่องแก้ก่อน
    draftRev: {
      field: 'draft_rev',
      type: INTEGER,
      allowNull: false,
      defaultValue: 1
    },
    publishedVersionId: {
      field: 'published_version_id',
      type: INTEGER
    },
    createdAt: { type: DATE, defaultValue: fnDateNow },
    updatedAt: { type: DATE, defaultValue: fnDateNow }
  }

  const options = {
    modelName: 'StarCard',
    tableName: 'star_cards',
    timestamps: true,
    paranoid: true,
    underscored: true,
    schema: dbConfig.schema,
    sequelize
  }

  class StarCard extends Sequelize.Model {}
  StarCard.init(attributes, options)
  StarCard.associate = (models) => {
    StarCard.belongsTo(models.User, {
      foreignKey: { name: 'userId', field: 'user_id' }
    })
    StarCard.hasMany(models.StarCardVersion, {
      foreignKey: { name: 'cardId', field: 'card_id' },
      as: 'versions'
    })
    StarCard.belongsTo(models.StarCardVersion, {
      foreignKey: { name: 'publishedVersionId', field: 'published_version_id' },
      as: 'published',
      constraints: false
    })
    StarCard.hasMany(models.StarCardImage, {
      foreignKey: { name: 'cardId', field: 'card_id' },
      as: 'images'
    })
  }

  return StarCard
}
