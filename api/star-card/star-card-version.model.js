// ตัวอย่าง — วางที่ microservices/user-service/src/models/star-card-version.model.js
// ฉบับที่กด "เผยแพร่" แล้ว — แก้ไม่ได้ เผยแพร่ใหม่ = แถวใหม่
import moment from 'moment'

export default (sequelize, { DATE, JSONB, INTEGER, SMALLINT, STRING, ARRAY }, dbConfig, Sequelize) => {
  const fnDateNow = () => moment().utcOffset('+07:00').format('YYYY-MM-DDTHH:mm:ss+07:00')

  const attributes = {
    id: {
      allowNull: false,
      autoIncrement: true,
      primaryKey: true,
      type: INTEGER
    },
    cardId: {
      field: 'card_id',
      type: INTEGER,
      allowNull: false
    },
    version: {
      type: INTEGER,
      allowNull: false
    },
    schemaVersion: {
      field: 'schema_version',
      type: SMALLINT,
      allowNull: false
    },
    // สำเนาของ draft_doc ณ ตอนกดเผยแพร่
    doc: {
      type: JSONB,
      allowNull: false
    },
    // PNG ที่เครื่องผู้แต่งวาดไว้ หนึ่งรูปต่อหน้า (image-service imageId)
    // ใช้บนเว็บ ในพรีวิวลิงก์ และตอนแอปอีกฝั่งยังไม่รู้จัก widget บางตัว
    pageImageIds: {
      field: 'page_image_ids',
      type: JSONB,
      allowNull: false
    },
    // 1200×630 สำหรับ og:image (LINE / Facebook)
    ogImageId: {
      field: 'og_image_id',
      type: INTEGER
    },
    // kind ทั้งหมดที่ใช้ในใบนี้ — แอปเช็กกับของที่ตัวเองรู้จัก ถ้าขาดตัวไหนก็โชว์ PNG แทน
    kinds: {
      type: ARRAY(STRING),
      allowNull: false
    },
    // แต่งมาจากเครื่องไหน เวอร์ชันอะไร — ไว้ไล่บั๊ก "iOS เห็นอย่าง Android เห็นอีกอย่าง"
    platform: {
      type: STRING(16)
    },
    appVersion: {
      field: 'app_version',
      type: STRING(16)
    },
    createdAt: { type: DATE, defaultValue: fnDateNow },
    updatedAt: { type: DATE, defaultValue: fnDateNow }
  }

  const options = {
    modelName: 'StarCardVersion',
    tableName: 'star_card_versions',
    timestamps: true,
    underscored: true,
    schema: dbConfig.schema,
    sequelize
  }

  class StarCardVersion extends Sequelize.Model {}
  StarCardVersion.init(attributes, options)
  StarCardVersion.associate = (models) => {
    StarCardVersion.belongsTo(models.StarCard, {
      foreignKey: { name: 'cardId', field: 'card_id' }
    })
  }

  return StarCardVersion
}
